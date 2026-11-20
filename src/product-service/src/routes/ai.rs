//////////////////////////
// Proxy for AI service
//////////////////////////

use std::collections::HashMap;
use std::fmt;
use std::time::Duration;
use actix_web::{web, Error, HttpRequest, HttpResponse, ResponseError};
use crate::startup::AppState;
use futures_util::StreamExt;

#[derive(Debug)]
pub struct ProxyError(reqwest::Error);

impl fmt::Display for ProxyError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl ResponseError for ProxyError {
    fn error_response(&self) -> HttpResponse {
        HttpResponse::InternalServerError().json(self.0.to_string())
    }
}

impl From<reqwest::Error> for ProxyError {
    fn from(err: reqwest::Error) -> ProxyError {
        ProxyError(err)
    }
}

/// Forward an ai-service response verbatim: status and body pass through
/// untouched (200s, 422/400/413 caller errors, 503 all-providers-failed).
/// The proxy only invents a 500 for its OWN failures (unreachable upstream,
/// unreadable body). Bodies pass through re-serialized when they match the
/// string-map contract, raw otherwise.
fn map_upstream_response(
    status: reqwest::StatusCode,
    body_text: String,
) -> (actix_web::http::StatusCode, String) {
    let body_json = match serde_json::from_str::<HashMap<String, String>>(&body_text) {
        Ok(map) => serde_json::to_string(&map).unwrap(),
        Err(_) => body_text,
    };
    (
        actix_web::http::StatusCode::from_u16(status.as_u16())
            .unwrap_or(actix_web::http::StatusCode::INTERNAL_SERVER_ERROR),
        body_json,
    )
}

pub async fn ai_health(data: web::Data<AppState>) -> Result<HttpResponse, Error> {
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.get(ai_service_url + "/health").send().await {
        Ok(resp) => resp,
        Err(e) => {
            return Ok(HttpResponse::InternalServerError().json(e.to_string()))
        }
    };
    let status = resp.status();
    if status.is_success() {
        let body_text = resp.text().await.map_err(ProxyError::from)?;
        Ok(HttpResponse::Ok().body(body_text))
    } else {
        Ok(HttpResponse::build(actix_web::http::StatusCode::NOT_FOUND).body(""))
    }
}

pub async fn ai_generate_description(data: web::Data<AppState>, mut payload: web::Payload) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.post( ai_service_url + "/generate/description")
    .body(body.to_vec())
    // Never hang forever on a stalled upstream: 660s covers the 600s AI
    // chain deadline plus margin, then the caller gets a 500, not silence.
    .timeout(Duration::from_secs(660))
    .send()
    .await {
        Ok(resp) => resp,
        Err(e) => {
            return Ok(HttpResponse::InternalServerError().json(e.to_string()))
        }
    };

    let status = resp.status();
    let body_text = resp.text().await.map_err(ProxyError::from)?;
    let (code, body_json) = map_upstream_response(status, body_text);
    Ok(HttpResponse::build(code).body(body_json))
}

pub async fn ai_upload_image(data: web::Data<AppState>, req: HttpRequest, mut payload: web::Payload) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    // Multipart uploads carry the boundary in Content-Type - it MUST be
    // forwarded or ai-service cannot parse the form (JSON proxy above
    // gets away without it, file uploads do not).
    let content_type = req.headers().get(actix_web::http::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("multipart/form-data")
        .to_owned();
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.post( ai_service_url + "/generate/image/upload")
    .header("Content-Type", content_type)
    .body(body.to_vec())
    // Never hang forever on a stalled upstream: 660s covers the 600s AI
    // chain deadline plus margin, then the caller gets a 500, not silence.
    .timeout(Duration::from_secs(660))
    .send()
    .await {
        Ok(resp) => resp,
        Err(e) => {
            return Ok(HttpResponse::InternalServerError().json(e.to_string()))
        }
    };

    let status = resp.status();
    let body_text = resp.text().await.map_err(ProxyError::from)?;
    let (code, body_json) = map_upstream_response(status, body_text);
    Ok(HttpResponse::build(code).body(body_json))
}

pub async fn ai_generate_image(data: web::Data<AppState>, mut payload: web::Payload) -> Result<HttpResponse, Error> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk?;
        body.extend_from_slice(&chunk);
    }
    let client = reqwest::Client::new();
    let ai_service_url = data.settings.ai_service_url.to_owned();
    let resp = match client.post( ai_service_url + "/generate/image")
    .body(body.to_vec())
    // Never hang forever on a stalled upstream: 660s covers the 600s AI
    // chain deadline plus margin, then the caller gets a 500, not silence.
    .timeout(Duration::from_secs(660))
    .send()
    .await {
        Ok(resp) => resp,
        Err(e) => {
            return Ok(HttpResponse::InternalServerError().json(e.to_string()))
        }
    };

    let status = resp.status();
    let body_text = resp.text().await.map_err(ProxyError::from)?;
    let (code, body_json) = map_upstream_response(status, body_text);
    Ok(HttpResponse::build(code).body(body_json))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn success_passes_through_as_200() {
        let (code, body) = map_upstream_response(
            reqwest::StatusCode::OK,
            r#"{"image":"data:x","provider":"upload"}"#.to_string(),
        );
        assert_eq!(code, actix_web::http::StatusCode::OK);
        assert!(body.contains("\"provider\":\"upload\""));
    }

    #[test]
    fn statuses_pass_through_verbatim() {
        for raw in [200u16, 400, 413, 422, 500, 503] {
            let (code, _) = map_upstream_response(
                reqwest::StatusCode::from_u16(raw).unwrap(),
                r#"{"error":"x"}"#.to_string(),
            );
            assert_eq!(code.as_u16(), raw);
        }
    }

    #[test]
    fn non_map_json_passes_through_raw() {
        let (code, body) = map_upstream_response(
            reqwest::StatusCode::OK,
            r#"["a","list"]"#.to_string(),
        );
        assert_eq!(code, actix_web::http::StatusCode::OK);
        assert_eq!(body, r#"["a","list"]"#);
    }
}