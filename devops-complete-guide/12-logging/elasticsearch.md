# Elasticsearch Complete Guide

## Table of Contents

1. [What Is Elasticsearch](#1-what-is-elasticsearch)
2. [Why Use Elasticsearch](#2-why-use-elasticsearch)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Mapping and Data Types](#7-mapping-and-data-types)
8. [Index Management](#8-index-management)
9. [Query DSL](#9-query-dsl)
10. [Aggregations](#10-aggregations)
11. [Cluster Management](#11-cluster-management)
12. [Security](#12-security)
13. [Performance Tuning](#13-performance-tuning)
14. [Backup and Recovery](#14-backup-and-recovery)
15. [Monitoring](#15-monitoring)
16. [Integration](#16-integration)
17. [Troubleshooting](#17-troubleshooting)
18. [Tips and Best Practices](#18-tips-and-best-practices)
19. [Command Reference](#19-command-reference)
20. [Configuration Reference](#20-configuration-reference)
21. [Real-World Examples](#21-real-world-examples)
22. [Further Reading](#22-further-reading)

---

## 1. What Is Elasticsearch

Elasticsearch is a distributed, RESTful search and analytics engine built on top of Apache Lucene. It provides a scalable, near real-time search engine with an HTTP web interface and schema-free JSON documents. Elasticsearch is the core component of the Elastic Stack (formerly ELK Stack), which includes Logstash, Kibana, and Beats.

### Key Characteristics

- **Distributed**: Data is automatically split across multiple nodes and shards
- **Near Real-Time (NRT)**: Documents become searchable within 1 second of indexing
- **Schema-Free**: Dynamic mapping allows flexible document structures
- **RESTful API**: All operations via HTTP methods (GET, POST, PUT, DELETE)
- **Built on Lucene**: Leverages Apache Lucene's powerful full-text search capabilities
- **Horizontal Scalability**: Add more nodes to increase capacity
- **Self-Healing**: Automatic replication and shard allocation

### Use Cases

- **Log Analytics**: Centralized logging with powerful search capabilities
- **Full-Text Search**: Product catalogs, content search, document search
- **Application Performance Monitoring**: Trace and metric analysis
- **Security Analytics**: Threat detection and incident response
- **Business Intelligence**: Real-time analytics on business data
- **Metrics Collection**: Infrastructure and application metrics
- **Event Data**: Time-series event data for dashboards

### Version History

| Version | Release | Key Features |
|---------|---------|--------------|
| 8.x | 2022+ | Improved security, vector search, synthetic _source |
| 7.x | 2019 | Java 11, EQL, runtime fields |
| 6.x | 2017 | Java 8, removal of types, cross-cluster replication |
| 5.x | 2016 | Grok, ingest pipelines, X-Pack |

---

## 2. Why Use Elasticsearch

### Advantages Over Alternatives

**Compared to Relational Databases:**
- Superior full-text search performance
- Horizontal scaling without complex sharding logic
- Near real-time indexing without expensive reindex operations
- Flexible schema for heterogeneous data

**Compared to Solr:**
- Better distributed architecture
- More intuitive REST API
- Superior cluster management
- Better ecosystem integration (Beats, Logstash)

**Compared to NoSQL (MongoDB, Couchbase):**
- Purpose-built for search and analytics
- More powerful query DSL
- Better aggregation framework
- Superior full-text search capabilities

### When Elasticsearch Excels

- You need full-text search with relevance scoring
- You have high-volume log data to analyze
- You need real-time search and analytics
- Your data has complex relationships that benefit from denormalization
- You need geospatial search capabilities
- You want a single engine for search AND analytics

### When NOT to Use Elasticsearch

- Simple key-value lookups (use Redis)
- ACID transactions required (use RDBMS)
- Small datasets that fit in a single database
- Heavy write-heavy workloads with no search requirements
- Strict relational data with complex joins

---

## 3. Architecture Overview

### Cluster Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Elasticsearch Cluster              │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │   Master Node │  │   Master Node │  │   Master   │ │
│  │   (Node 1)    │  │   (Node 2)    │  │   (Node 3)│ │
│  └──────────────┘  └──────────────┘  └────────────┘ │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Data Node 1  │  │  Data Node 2  │  │ Data Node 3│ │
│  │ ┌────┐┌────┐ │  │ ┌────┐┌────┐ │  │ ┌────┐     │ │
│  │ │Shd0││Shd1│ │  │ │Shd0││Shd2│ │  │ │Shd1│     │ │
│  │ └────┘└────┘ │  │ └────┘└────┘ │  │ └────┘     │ │
│  │ ┌────┐       │  │       ┌────┐ │  │ ┌────┐     │ │
│  │ │Shd2│       │  │       │Shd1│ │  │ │Shd0│     │ │
│  │ └────┘       │  │       └────┘ │  │ └────┘     │ │
│  └──────────────┘  └──────────────┘  └────────────┘ │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐                  │
│  │  Ingest Node  │  │  Coordinating │                  │
│  │  (Pipeline)   │  │    Node       │                  │
│  └──────────────┘  └──────────────┘                  │
└─────────────────────────────────────────────────────┘
```

### Node Types

| Node Type | Role | Description |
|-----------|------|-------------|
| Master | Cluster management | Manages index creation/deletion, shard allocation |
| Data | Store and search data | Holds shards, executes CRUD and search |
| Ingest | Pre-process documents | Execute ingest pipelines before indexing |
| Coordinating | Route requests | Scatter/gather queries across nodes |
| Machine Learning | ML jobs | Anomaly detection, analytics |

### Shards and Replicas

**Primary Shard**: Each document belongs to exactly one primary shard. The number of primary shards is fixed at index creation.

**Replica Shard**: Copy of a primary shard for fault tolerance. Replicas also serve read requests to increase throughput.

```
Index: logs-2024
  ├── Primary Shards: 5 (shard 0-4)
  └── Replica Shards: 1 per primary (5 total)
  
  Total shards: 10
  Data spread across nodes via shard allocation
```

### Index Lifecycle

1. **Warm**: New data, most recent, fully searchable
2. **Hot**: Recently indexed, frequently queried
3. **Warm**: Less frequently queried, can be force-merged
4. **Cold**: Rarely queried, compressible
5. **Delete**: Data older than retention period

---

## 4. Installation

### Prerequisites

```bash
# System requirements
- RAM: 16GB minimum (32GB+ recommended)
- CPU: 4+ cores recommended
- Disk: SSD recommended, at least 50GB free
- File descriptors: 65536
- Virtual memory: 262144
- Swap: Disabled or vm.swappiness=1
```

### Install on Ubuntu/Debian

```bash
# Import Elastic GPG key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Install Elasticsearch
sudo apt-get update
sudo apt-get install elasticsearch

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

### Install on RHEL/CentOS

```bash
# Import key
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Add repo
cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-8.x]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install
sudo yum install elasticsearch
sudo systemctl enable --now elasticsearch
```

### Install with Docker

```bash
# Single node
docker run -d \
  --name elasticsearch \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  -e "ES_JAVA_OPTS=-Xms2g -Xmx2g" \
  -v elasticsearch-data:/usr/share/elasticsearch/data \
  docker.elastic.co/elasticsearch/elasticsearch:8.12.0

# With security enabled
docker run -d \
  --name elasticsearch \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=true" \
  -e "ELASTIC_PASSWORD=changeme" \
  -e "ES_JAVA_OPTS=-Xms4g -Xmx4g" \
  -v es-data:/usr/share/elasticsearch/data \
  -v es-certs:/usr/share/elasticsearch/config/certs \
  docker.elastic.co/elasticsearch/elasticsearch:8.12.0
```

### Install with Docker Compose

```yaml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: elasticsearch
    environment:
      - node.name=elasticsearch
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=false
      - ELASTIC_PASSWORD=changeme
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - elastic
    healthcheck:
      test: ["CMD-SHELL", "curl -s -u elastic:changeme http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\"\\|\"status\":\"yellow\"'"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  es-data:
    driver: local

networks:
  elastic:
    driver: bridge
```

### Install with Kubernetes (ECK Operator)

```bash
# Install the operator
kubectl create -f https://download.elastic.co/downloads/eck/2.12.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.12.0/operator.yaml

# Create a cluster
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 8.12.0
  nodeSets:
  - name: default
    count: 3
    config:
      node.store.allow_mmap: false
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 4Gi
              cpu: 1
            limits:
              memory: 4Gi
              cpu: 1
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
EOF
```

---

## 5. Configuration

### elasticsearch.yml (Main Config)

```yaml
# ======================== Elasticsearch Configuration ========================

# Cluster name (must match across all nodes)
cluster.name: my-elastic-cluster

# Node name (unique per node)
node.name: node-1

# Node roles
node.roles: [master, data, ingest]

# Path configuration
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

# Network configuration
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

# Discovery (for multi-node clusters)
discovery.seed_hosts:
  - node-1:9300
  - node-2:9300
  - node-3:9300
cluster.initial_master_nodes:
  - node-1
  - node-2
  - node-3

# Memory
bootstrap.memory_lock: true

# Security
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.enabled: true

# Monitoring
xpack.monitoring.collection.enabled: true

# Index settings
action.auto_create_index: true
action.destructive_requires_name: true
```

### JVM Settings (jvm.options)

```
# Heap size (set to 50% of available RAM, max 31GB)
-Xms16g
-Xmx16g

# GC settings (G1GC recommended)
-XX:+UseG1GC
-XX:G1HeapRegionSize=4m
-XX:InitiatingHeapOccupancyPercent=30
-XX:G1ReservePercent=15

# Memory settings
-XX:+AlwaysPreTouch
-XX:-OmitStackTraceInFastThrow

# Debug settings (for production troubleshooting)
#-XX:+HeapDumpOnOutOfMemoryError
#-XX:HeapDumpPath=/var/lib/elasticsearch/heapdump.hprof
```

### System Tuning

```bash
# /etc/sysctl.conf
vm.max_map_count=262144
vm.swappiness=1
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=65535

# /etc/security/limits.conf
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
elasticsearch soft nofile 65536
elasticsearch hard nofile 65536
elasticsearch soft nproc 4096
elasticsearch hard nproc 4096
```

---

## 6. Core Concepts

### Documents

A document is the basic unit of information in Elasticsearch, expressed in JSON.

```json
{
  "_index": "my-index",
  "_id": "1",
  "_version": 1,
  "_seq_no": 0,
  "_primary_term": 1,
  "found": true,
  "_source": {
    "title": "Elasticsearch Guide",
    "author": "John Doe",
    "date": "2024-01-15",
    "content": "This is a comprehensive guide...",
    "tags": ["search", "analytics", "database"],
    "views": 1500
  }
}
```

### Indexes

An index is a collection of documents with similar characteristics.

```
Index Lifecycle:
  Create → Index Documents → Search → Update → Delete

Index Naming Conventions:
  logs-2024.01.15    (daily logs)
  logs-app-*         (wildcard pattern)
  products-v2        (versioned index)
  my-index-000001    (rollover pattern)
```

### Shards

```bash
# Create index with specific shard configuration
PUT /my-index
{
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 1,
    "routing.allocation.require.node_type": "hot"
  }
}

# Check shard allocation
GET /_cat/shards?v
GET /_cat/shards/my-index?v

# Reroute shards
POST /_cluster/reroute
{
  "commands": [
    {
      "move": {
        "index": "my-index",
        "shard": 0,
        "from_node": "node-1",
        "to_node": "node-2"
      }
    }
  ]
}
```

### Replicas

```bash
# Update replica count
PUT /my-index/_settings
{
  "number_of_replicas": 2
}

# Wait for active shards
POST /my-index/_doc/1
{
  "title": "Document"
}
?wait_for_active_shards=2
```

### Refresh and Flush

```bash
# Manual refresh (make documents searchable)
POST /my-index/_refresh

# Flush (force write to disk)
POST /my-index/_flush

# Configure refresh interval
PUT /my-index/_settings
{
  "index": {
    "refresh_interval": "30s"
  }
}
```

---

## 7. Mapping and Data Types

### Dynamic Mapping

```json
// Elasticsearch auto-detects types
PUT /my-index/_doc/1
{
  "text_field": "hello world",          // text + keyword
  "number_field": 42,                   // long
  "float_field": 3.14,                  // float
  "boolean_field": true,                // boolean
  "date_field": "2024-01-15",           // date
  "array_field": [1, 2, 3],            // long
  "object_field": {                     // object
    "nested_key": "value"
  }
}
```

### Explicit Mapping

```json
PUT /my-index
{
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "english",
        "fields": {
          "keyword": {
            "type": "keyword",
            "ignore_above": 256
          }
        }
      },
      "date": {
        "type": "date",
        "format": "yyyy-MM-dd||yyyy-MM-dd HH:mm:ss||epoch_millis"
      },
      "status": {
        "type": "keyword"
      },
      "count": {
        "type": "integer"
      },
      "location": {
        "type": "geo_point"
      },
      "tags": {
        "type": "keyword"
      },
      "content": {
        "type": "text",
        "analyzer": "standard"
      }
    }
  }
}
```

### Common Data Types

| Type | Description | Example |
|------|-------------|---------|
| text | Full-text searchable | "Hello World" |
| keyword | Exact value, used for filtering | "published" |
| long | 64-bit integer | 1234567890 |
| integer | 32-bit integer | 42 |
| float | Single precision float | 3.14 |
| double | Double precision float | 3.14159 |
| boolean | True/false | true |
| date | Date/time | "2024-01-15" |
| geo_point | Lat/lon coordinates | {"lat": 40.7, "lon": -74.0} |
| nested | Array of objects | [{"name":"a"},{"name":"b"}] |
| object | JSON object | {"key": "value"} |
| ip | IPv4/IPv6 address | "192.168.1.1" |
| completion | Autocomplete suggestions | {"input":["elasticsearch"]} |

### Multi-Fields

```json
"message": {
  "type": "text",
  "fields": {
    "keyword": {
      "type": "keyword",
      "ignore_above": 256
    },
    "analyzed": {
      "type": "text",
      "analyzer": "custom_analyzer"
    }
  }
}
```

### Nested Objects

```json
PUT /blog-posts
{
  "mappings": {
    "properties": {
      "comments": {
        "type": "nested",
        "properties": {
          "author": { "type": "keyword" },
          "content": { "type": "text" },
          "date": { "type": "date" }
        }
      }
    }
  }
}

// Query nested objects
GET /blog-posts/_search
{
  "query": {
    "nested": {
      "path": "comments",
      "query": {
        "match": { "comments.author": "john" }
      }
    }
  }
}
```

---

## 8. Index Management

### Create Index

```json
PUT /logs-2024.01
{
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 1,
    "index.lifecycle.name": "logs-policy",
    "index.lifecycle.rollover_alias": "logs-write"
  },
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "message": { "type": "text" },
      "level": { "type": "keyword" },
      "service": { "type": "keyword" },
      "host": { "type": "keyword" }
    }
  }
}
```

### Index Lifecycle Management (ILM)

```json
PUT /_ilm/policy/logs-policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": {
            "number_of_shards": 1
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "set_priority": {
            "priority": 0
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Rollover

```json
// Create initial index with write alias
PUT /logs-000001
{
  "aliases": {
    "logs-write": {
      "is_write_index": true
    },
    "logs-read": {}
  }
}

// Trigger rollover
POST /logs-write/_rollover
{
  "conditions": {
    "max_age": "7d",
    "max_docs": 100000000,
    "max_primary_shard_size": "50gb"
  }
}
```

### Reindex

```json
// Simple reindex
POST /_reindex
{
  "source": { "index": "old-index" },
  "dest": { "index": "new-index" }
}

// Reindex with query
POST /_reindex
{
  "source": {
    "index": "logs-*",
    "query": {
      "range": {
        "@timestamp": {
          "gte": "2024-01-01",
          "lt": "2024-02-01"
        }
      }
    }
  },
  "dest": {
    "index": "logs-january-2024"
  }
}

// Reindex with script
POST /_reindex
{
  "source": { "index": "users" },
  "dest": { "index": "users-v2" },
  "script": {
    "source": "ctx._source.fullName = ctx._source.firstName + ' ' + ctx._source.lastName",
    "lang": "painless"
  }
}
```

### Aliases

```json
// Add alias
POST /_aliases
{
  "actions": [
    { "add": { "index": "logs-2024.01", "alias": "logs-current" } }
  ]
}

// Remove alias
POST /_aliases
{
  "actions": [
    { "remove": { "index": "logs-2024.01", "alias": "logs-current" } }
  ]
}

// Alias with filter
POST /_aliases
{
  "actions": [
    {
      "add": {
        "index": "logs-*",
        "alias": "logs-errors",
        "filter": {
          "term": { "level": "ERROR" }
        }
      }
    }
  ]
}
```

### Templates

```json
// Index template
PUT /_index_template/logs-template
{
  "index_patterns": ["logs-*"],
  "priority": 100,
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message": { "type": "text" }
      }
    }
  }
}
```

---

## 9. Query DSL

### Match Query

```json
// Full-text search
GET /my-index/_search
{
  "query": {
    "match": {
      "message": {
        "query": "elasticsearch search engine",
        "operator": "and",
        "fuzziness": "AUTO"
      }
    }
  }
}

// Match phrase
GET /my-index/_search
{
  "query": {
    "match_phrase": {
      "message": "elasticsearch search"
    }
  }
}
```

### Term Query

```json
// Exact match (keyword fields)
GET /my-index/_search
{
  "query": {
    "term": {
      "status": "published"
    }
  }
}

// Terms query (multiple values)
GET /my-index/_search
{
  "query": {
    "terms": {
      "status": ["published", "draft", "archived"]
    }
  }
}
```

### Range Query

```json
GET /my-index/_search
{
  "query": {
    "range": {
      "date": {
        "gte": "2024-01-01",
        "lt": "2024-02-01",
        "format": "yyyy-MM-dd"
      }
    }
  }
}

GET /my-index/_search
{
  "query": {
    "range": {
      "price": {
        "gte": 10,
        "lte": 100
      }
    }
  }
}
```

### Boolean Query

```json
GET /my-index/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "title": "elasticsearch" } }
      ],
      "filter": [
        { "term": { "status": "published" } },
        { "range": { "date": { "gte": "2024-01-01" } } }
      ],
      "must_not": [
        { "term": { "status": "draft" } }
      ],
      "should": [
        { "match": { "tags": "tutorial" } },
        { "match": { "tags": "guide" } }
      ],
      "minimum_should_match": 1
    }
  }
}
```

### Multi-Match Query

```json
GET /my-index/_search
{
  "query": {
    "multi_match": {
      "query": "elasticsearch tutorial",
      "fields": ["title^3", "content^2", "description"],
      "type": "best_fields",
      "fuzziness": "AUTO"
    }
  }
}
```

### Wildcard and Regex

```json
// Wildcard
GET /my-index/_search
{
  "query": {
    "wildcard": {
      "title": {
        "value": "elastic*",
        "case_insensitive": true
      }
    }
  }
}

// Regex
GET /my-index/_search
{
  "query": {
    "regexp": {
      "title": {
        "value": "elasticsearch.*guide",
        "flags": "ALL"
      }
    }
  }
}
```

### Exists Query

```json
GET /my-index/_search
{
  "query": {
    "exists": {
      "field": "tags"
    }
  }
}
```

### Script Score Query

```json
GET /my-index/_search
{
  "query": {
    "script_score": {
      "query": { "match_all": {} },
      "script": {
        "source": "doc['views'].value * params.factor",
        "params": {
          "factor": 0.1
        }
      }
    }
  }
}
```

---

## 10. Aggregations

### Bucket Aggregations

```json
// Terms aggregation
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "by_level": {
      "terms": {
        "field": "level",
        "size": 10,
        "order": { "_count": "desc" }
      }
    }
  }
}

// Histogram
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "requests_over_time": {
      "histogram": {
        "field": "response_time",
        "interval": 100,
        "extended_bounds": {
          "min": 0,
          "max": 1000
        }
      }
    }
  }
}

// Date histogram
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "logs_per_day": {
      "date_histogram": {
        "field": "@timestamp",
        "calendar_interval": "day",
        "format": "yyyy-MM-dd"
      }
    }
  }
}
```

### Metrics Aggregations

```json
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "response_stats": {
      "extended_stats": {
        "field": "response_time"
      }
    },
    "percentiles": {
      "percentiles": {
        "field": "response_time",
        "percents": [50, 75, 90, 95, 99]
      }
    },
    "unique_services": {
      "cardinality": {
        "field": "service"
      }
    }
  }
}
```

### Pipeline Aggregations

```json
// Moving average
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "requests_per_hour": {
      "date_histogram": {
        "field": "@timestamp",
        "fixed_interval": "1h"
      },
      "aggs": {
        "moving_avg": {
          "moving_fn": {
            "script": "MovingFunctions.unweightedMovAvg(values)",
            "buckets_path": "_count",
            "window": 12
          }
        }
      }
    }
  }
}
```

### Nested Aggregations

```json
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "by_service": {
      "terms": {
        "field": "service"
      },
      "aggs": {
        "by_level": {
          "terms": {
            "field": "level"
          },
          "aggs": {
            "avg_response_time": {
              "avg": {
                "field": "response_time"
              }
            }
          }
        }
      }
    }
  }
}
```

### Filters and Post Filters

```json
// Filter aggregation
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "errors_only": {
      "filter": {
        "term": { "level": "ERROR" }
      },
      "aggs": {
        "error_services": {
          "terms": {
            "field": "service"
          }
        }
      }
    }
  }
}

// Post filter (affects hits but not aggregations)
GET /logs-*/_search
{
  "size": 10,
  "post_filter": {
    "term": {
      "level": "ERROR"
    }
  }
}
```

---

## 11. Cluster Management

### Cluster Health

```bash
GET /_cluster/health
# Response:
# {
#   "cluster_name": "my-cluster",
#   "status": "green",
#   "number_of_nodes": 5,
#   "number_of_data_nodes": 3,
#   "active_primary_shards": 15,
#   "active_shards": 30,
#   "relocating_shards": 0,
#   "initializing_shards": 0,
#   "unassigned_shards": 0
# }

# Wait for green status
GET /_cluster/health?wait_for_status=green&timeout=30s
```

### Node Stats

```bash
# All nodes
GET /_cat/nodes?v

# Node stats
GET /_nodes/stats

# Specific node
GET /_nodes/node-1/stats

# Hot threads
GET /_nodes/hot_threads
```

### Shard Allocation

```bash
# Check shard allocation
GET /_cat/shards?v

# Disable allocation (for maintenance)
PUT /_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": "none"
  }
}

# Re-enable allocation
PUT /_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": "all"
  }
}

# Move shard
POST /_cluster/reroute
{
  "commands": [
    {
      "move": {
        "index": "my-index",
        "shard": 0,
        "from_node": "node-1",
        "to_node": "node-2"
      }
    }
  ]
}

# Cancel shard allocation
POST /_cluster/reroute
{
  "commands": [
    {
      "cancel": {
        "index": "my-index",
        "shard": 0,
        "node": "node-1"
      }
    }
  ]
}

# Allocate stale primary
POST /_cluster/reroute
{
  "commands": [
    {
      "allocate_stale_primary": {
        "index": "my-index",
        "shard": 0,
        "node": "node-1",
        "accept_data_loss": true
      }
    }
  ]
}
```

### Pending Tasks

```bash
GET /_cluster/pending_tasks
```

### Thread Pool Stats

```bash
GET /_cat/thread_pool?v
GET /_cat/thread_pool/search?v
```

---

## 12. Security

### Enable Security

```yaml
# elasticsearch.yml
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.enabled: true

# SSL certificates
xpack.security.transport.ssl.keystore.path: certs/transport.p12
xpack.security.transport.ssl.truststore.path: certs/transport.p12
xpack.security.http.ssl.keystore.path: certs/http.p12
```

### Create Users

```bash
# Setup passwords (run once)
bin/elasticsearch-setup-passwords interactive

# Create user via API
POST /_security/user/john
{
  "password": "securepassword123",
  "roles": ["kibana_admin", "logs_reader"],
  "full_name": "John Doe",
  "email": "john@example.com"
}

# Create role
POST /_security/role/logs_reader
{
  "indices": [
    {
      "names": ["logs-*"],
      "privileges": ["read", "view_index_metadata"],
      "field_security": {
        "grant": ["*"]
      }
    }
  ]
}

# API key
POST /_security/api_key
{
  "name": "my-api-key",
  "role_descriptors": {
    "logs_reader": {
      "indices": [
        {
          "names": ["logs-*"],
          "privileges": ["read"]
        }
      ]
    }
  },
  "metadata": {
    "application": "my-application"
  }
}
```

### Role-Based Access Control

```json
// Read-only role for specific indices
POST /_security/role/logs_reader
{
  "indices": [
    {
      "names": ["logs-*", "monitoring-*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["feature_discover.read", "feature_dashboard.read"],
      "resources": ["*"]
    }
  ]
}

// Admin role
POST /_security/role/cluster_admin
{
  "cluster": ["manage"],
  "indices": [
    {
      "names": ["*"],
      "privileges": ["all"]
    }
  ]
}
```

---

## 13. Performance Tuning

### Index Performance

```bash
# Increase refresh interval for bulk indexing
PUT /my-index/_settings
{
  "index": {
    "refresh_interval": "-1"
  }
}

# Disable replicas during bulk load
PUT /my-index/_settings
{
  "number_of_replicas": 0
}

# Use bulk API
POST /_bulk
{"index":{"_index":"my-index","_id":"1"}}
{"title":"Doc 1","content":"Content 1"}
{"index":{"_index":"my-index","_id":"2"}}
{"title":"Doc 2","content":"Content 2"}

# Optimize after bulk load
POST /my-index/_forcemerge?max_num_segments=1
PUT /my-index/_settings
{
  "number_of_replicas": 1,
  "refresh_interval": "1s"
}
```

### Query Performance

```json
// Use filter context for exact matches
GET /my-index/_search
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "status": "published" } },
        { "range": { "date": { "gte": "2024-01-01" } } }
      ],
      "must": [
        { "match": { "content": "search query" } }
      ]
    }
  }
}

// Use source filtering
GET /my-index/_search
{
  "_source": ["title", "date"],
  "query": {
    "match": { "title": "elasticsearch" }
  }
}

// Use terminate_after for counting
GET /my-index/_search
{
  "size": 0,
  "terminate_after": 1000,
  "aggs": {
    "count": {
      "value_count": {
        "field": "_id"
      }
    }
  }
}
```

### Cache Configuration

```bash
# Request cache statistics
GET /_nodes/stats/indices/request_cache

# Clear request cache
POST /my-index/_cache/clear

# Stats for query cache
GET /_nodes/stats/indices/query_cache
```

### Memory Settings

```yaml
# Field data circuit breaker
indices.breaker.fielddata.limit: 60%
indices.breaker.fielddata.overhead: 1.03
indices.breaker.request.limit: 40%
indices.breaker.accounting.limit: 100%

# Fielddata cache size
indices.fielddata.cache.size: 20%

# Off-heap storage (Lucene MMapDirectory)
index.store.type: mmapfs
```

---

## 14. Backup and Recovery

### Snapshot Repository

```json
// Register repository
PUT /_snapshot/my_backup
{
  "type": "fs",
  "settings": {
    "location": "/mount/backups/elasticsearch",
    "compress": true,
    "max_snapshot_bytes_per_sec": "50mb",
    "max_restore_bytes_per_sec": "50mb"
  }
}
```

### Create Snapshot

```json
// Full snapshot
PUT /_snapshot/my_backup/snapshot_2024_01_15

// Partial snapshot
PUT /_snapshot/my_backup/snapshot_partial?wait_for_completion=true
{
  "indices": "logs-*",
  "ignore_unavailable": true,
  "include_global_state": false
}
```

### Restore Snapshot

```json
// Restore all
POST /_snapshot/my_backup/snapshot_2024_01_15/_restore

// Restore specific indices
POST /_snapshot/my_backup/snapshot_2024_01_15/_restore
{
  "indices": "logs-2024.01*",
  "ignore_unavailable": true,
  "include_global_state": false,
  "rename_pattern": "(.+)",
  "rename_replacement": "restored_$1"
}
```

### Automated Snapshots (Cron)

```bash
#!/bin/bash
# /usr/local/bin/es-backup.sh

REPO="my_backup"
SNAPSHOT="backup_$(date +%Y%m%d_%H%M%S)"
ES_URL="http://localhost:9200"

# Create snapshot
curl -s -X PUT "${ES_URL}/_snapshot/${REPO}/${SNAPSHOT}?wait_for_completion=true" \
  -H 'Content-Type: application/json' \
  -d '{
    "indices": "logs-*,monitoring-*",
    "ignore_unavailable": true,
    "include_global_state": false
  }'

# Cleanup old snapshots (keep last 7)
curl -s "${ES_URL}/_snapshot/${REPO}/_snapshots" | \
  jq -r '.snapshots | sort_by(.start_time) | .[:-7] | .[].snapshot' | \
  while read snap; do
    curl -s -X DELETE "${ES_URL}/_snapshot/${REPO}/${snap}"
  done
```

---

## 15. Monitoring

### Built-in Monitoring

```yaml
# Enable monitoring
xpack.monitoring.collection.enabled: true
xpack.monitoring.collection.interval: 10s
```

### Stats APIs

```bash
# Cluster stats
GET /_cluster/stats

# Node stats
GET /_nodes/stats

# Index stats
GET /_stats

# Specific index stats
GET /my-index/_stats

# Segment info
GET /_cat/segments?v

# Recovery status
GET /_cat/recovery?v

# Pending tasks
GET /_cluster/pending_tasks
```

### Custom Monitoring

```json
// Index for monitoring data
PUT /monitoring-{YYYY.MM.dd}
{
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "metric_name": { "type": "keyword" },
      "metric_value": { "type": "double" },
      "node": { "type": "keyword" },
      "cluster": { "type": "keyword" }
    }
  }
}
```

### Prometheus Exporter

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'elasticsearch'
    metrics_path: '/_prometheus/metrics'
    static_configs:
      - targets: ['localhost:9200']
    basic_auth:
      username: 'elastic'
      password: 'changeme'
```

---

## 16. Integration

### With Fluentd

```xml
# Fluentd config
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match **>
  @type elasticsearch
  host localhost
  port 9200
  index_name logs
  type_name _doc
  logstash_format true
  logstash_prefix logs
  include_tag_key true
  flush_interval 5s
  <buffer>
    flush_mode interval
    retry_type exponential_backoff
    flush_interval 5s
    chunk_limit_size 2M
    queue_limit_length 32
  </buffer>
</match>
```

### With Logstash

```ruby
# logstash.conf
input {
  file {
    path => "/var/log/app/*.log"
    start_position => "beginning"
    sincedb_path => "/var/lib/logstash/sincedb"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
  date {
    match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
  }
  geoip {
    source => "clientip"
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "logs-%{+YYYY.MM.dd}"
    user => "elastic"
    password => "changeme"
  }
}
```

### With Filebeat

```yaml
# filebeat.yml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/app/*.log
    fields:
      service: myapp
      environment: production
    multiline:
      pattern: '^\d{4}-\d{2}-\d{2}'
      negate: true
      match: after

output.elasticsearch:
  hosts: ["localhost:9200"]
  username: "elastic"
  password: "changeme"
  index: "filebeat-%{[agent.version]}-%{+yyyy.MM.dd}"

setup.template.name: "filebeat"
setup.template.pattern: "filebeat-*"
setup.ilm.enabled: true
```

### With Kibana

```yaml
# kibana.yml
elasticsearch.hosts: ["http://localhost:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "changeme"
server.port: 5601
server.host: "0.0.0.0"
```

---

## 17. Troubleshooting

### Issue 1: Cluster Status Red

```bash
# Diagnosis
GET /_cluster/health
GET /_cat/shards?v&h=index,shard,prirep,state,unassigned.reason

# Common causes:
# - Unassigned primary shards (data loss or disk space)
# - Disk watermark exceeded

# Fix: Check disk space
df -h
GET /_cat/allocation?v

# Clear disk watermark
PUT /_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.disk.watermark.low": "90%",
    "cluster.routing.allocation.disk.watermark.high": "95%",
    "cluster.routing.allocation.disk.watermark.flood_stage": "97%"
  }
}
```

### Issue 2: OutOfMemoryError

```bash
# Check heap usage
GET /_cat/nodes?v&h=name,heap.percent,heap.max,ram.max

# Fix: Increase heap
# Edit jvm.options
-Xms16g
-Xmx16g

# Check fielddata usage
GET /_cat/fielddata?v

# Clear fielddata cache
POST /_cache/clear

# Reduce fielddata limit
PUT /_cluster/settings
{
  "persistent": {
    "indices.breaker.fielddata.limit": "50%"
  }
}
```

### Issue 3: Slow Queries

```bash
# Enable slow log
PUT /my-index/_settings
{
  "index.search.slowlog.threshold.query.warn": "10s",
  "index.search.slowlog.threshold.query.info": "5s",
  "index.search.slowlog.threshold.query.debug": "2s",
  "index.search.slowlog.threshold.query.trace": "500ms",
  "index.search.slowlog.threshold.fetch.warn": "1s",
  "index.indexing.slowlog.threshold.index.warn": "10s"
}

# Profile query
GET /my-index/_search
{
  "profile": true,
  "query": {
    "match": { "content": "slow query" }
  }
}

# Check slow log
GET /my-index/_search?q=*
# Check /var/log/elasticsearch/elasticsearch_index_search_slowlog.log
```

### Issue 4: Disk Space Issues

```bash
# Check disk usage
GET /_cat/allocation?v

# Delete old indices
DELETE /logs-2023.*

# Force merge to reduce space
POST /my-index/_forcemerge?max_num_segments=1

# Shrink index
POST /my-index/_shrink/shrunk-my-index

# Read-only index
PUT /my-index/_settings
{
  "index.blocks.read_only_allow_delete": null
}
```

### Issue 5: Shard Allocation Issues

```bash
# Check allocation explain
GET /_cluster/allocation/explain

# Cancel stuck shard
POST /_cluster/reroute
{
  "commands": [
    {
      "cancel": {
        "index": "my-index",
        "shard": 0,
        "node": "node-1"
      }
    }
  ]
}

# Retry failed allocation
POST /_cluster/reroute?retry_failed=true
```

### Issue 6: Network Partition (Split Brain)

```bash
# Check node discovery
GET /_cat/nodes?v

# Verify quorum
GET /_cluster/health

# Fix: Set minimum master nodes
PUT /_cluster/settings
{
  "persistent": {
    "discovery.zen.minimum_master_nodes": 3
  }
}
```

### Issue 7: Index Replicas Not Active

```bash
# Check replica status
GET /my-index/_cat/shards?v

# Wait for replicas
GET /_cluster/health?wait_for_active_shards=all

# Manually assign replica
POST /_cluster/reroute
{
  "commands": [
    {
      "allocate_replica": {
        "index": "my-index",
        "shard": 0,
        "node": "node-2",
        "accept_data_loss": false
      }
    }
  ]
}
```

### Issue 8: Mapping Explosion

```bash
# Check mapping size
GET /my-index/_mapping

# Limit dynamic fields
PUT /my-index
{
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "title": { "type": "text" }
    }
  }
}

# Or limit with dynamic templates
PUT /my-index
{
  "mappings": {
    "dynamic_templates": [
      {
        "strings_as_keywords": {
          "match_mapping_type": "string",
          "mapping": {
            "type": "keyword",
            "ignore_above": 256
          }
        }
      }
    ]
  }
}
```

### Issue 9: High CPU Usage

```bash
# Check hot threads
GET /_nodes/hot_threads

# Check thread pool stats
GET /_cat/thread_pool?v

# Identify expensive queries
GET /_tasks?actions=*search*&detailed=true

# Cancel long-running tasks
POST /_tasks/task_id/_cancel
```

### Issue 10: Connection Refused

```bash
# Check if ES is running
systemctl status elasticsearch

# Check logs
tail -f /var/log/elasticsearch/elasticsearch.log

# Check port binding
ss -tlnp | grep 9200

# Check firewall
sudo ufw status
sudo iptables -L
```

### Issue 11: Disk Watermarks

```bash
# Check watermarks
GET /_cluster/settings?include_defaults=true&filter_path=**.watermark**

# Temporarily increase watermarks
PUT /_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.disk.watermark.low": "85%",
    "cluster.routing.allocation.disk.watermark.high": "90%"
  }
}

# Move data to larger disk
POST /_cluster/reroute
{
  "commands": [
    {
      "move": {
        "index": "my-index",
        "shard": 0,
        "from_node": "node-1",
        "to_node": "node-2"
      }
    }
  ]
}
```

### Issue 12: Version Mismatch

```bash
# Check versions
GET /
GET /_cat/nodes?v

# Upgrade process:
# 1. Stop Elasticsearch
# 2. Install new version
# 3. Start Elasticsearch
# 4. Wait for cluster health green

# Rolling upgrade
# Upgrade one node at a time
# Allow shard allocation to other nodes during upgrade
PUT /_cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}
```

### Issue 13: Index Corruption

```bash
# Check for corruption
GET /_cat/shards?v&h=index,shard,prirep,state,unassigned.reason

# Restore from snapshot
POST /_snapshot/my_backup/snapshot_2024_01_15/_restore
{
  "indices": "corrupted-index",
  "ignore_unavailable": true
}

# Force allocation (data loss possible)
POST /_cluster/reroute
{
  "commands": [
    {
      "allocate_stale_primary": {
        "index": "my-index",
        "shard": 0,
        "node": "node-1",
        "accept_data_loss": true
      }
    }
  ]
}
```

### Issue 14: Pipeline Failures

```bash
# Check pipeline stats
GET /_ingest/pipeline/*?pretty

# Test pipeline
POST /_ingest/pipeline/my-pipeline/_simulate
{
  "docs": [
    {
      "_source": {
        "message": "test log line"
      }
    }
  ]
}

# Re-execute pipeline on index
POST /my-index/_update_by_query
{
  "query": {
    "match_all": {}
  },
  "pipeline": "my-pipeline"
}
```

### Issue 15: Security Certificate Issues

```bash
# Check certificate validity
openssl x509 -in http.crt -noout -dates

# Regenerate certificates
bin/elasticsearch-certutil ca
bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12

# Copy certificates to nodes
scp http.crt node-2:/etc/elasticsearch/certs/
scp transport.crt node-2:/etc/elasticsearch/certs/

# Verify SSL connection
curl -u elastic:changeme https://localhost:9200 --cacert http.crt
```

### Issue 16: CCR (Cross-Cluster Replication) Lag

```bash
# Check follower stats
GET /follower-index/_ccr/stats

# Check lag
GET /_cluster/stats?include_follower_lag=true

# Resume lagging shards
POST /follower-index/_ccr/resume_follow
{
  "max_read_request_operation_count": 5120,
  "max_outstanding_read_requests": 12
}
```

### Issue 17: Index Template Not Applied

```bash
# Check existing templates
GET /_index_template
GET /_template

# Delete conflicting template
DELETE /_template/old-template

# Verify new index gets correct mapping
PUT /test-index-000001
GET /test-index-000001/_mapping
```

---

## 18. Tips and Best Practices

### Tip 1: Use Index Lifecycle Management

Always set up ILM from the beginning. Define hot, warm, cold, and delete phases with appropriate rollover conditions.

### Tip 2: Size Shards Properly

Aim for shard sizes between 10-50GB. Too many small shards waste resources; too few large shards limit parallelism.

### Tip 3: Use Filter Context for Constant Queries

```json
// BAD: Score recalculated for every query
{
  "query": {
    "bool": {
      "must": [
        { "term": { "status": "published" } }
      ]
    }
  }
}

// GOOD: Filter cached, no scoring
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "status": "published" } }
      ]
    }
  }
}
```

### Tip 4: Bulk Index in Batches

```bash
# Optimal batch size: 1000-5000 documents
# Or 5-15MB per request
POST /_bulk
# ... documents ...
```

### Tip 5: Disable Refresh During Bulk Loads

```bash
PUT /my-index/_settings
{ "index.refresh_interval": "-1" }
# ... bulk load ...
POST /my-index/_forcemerge?max_num_segments=1
PUT /my-index/_settings
{ "index.refresh_interval": "1s" }
```

### Tip 6: Use Source Filtering

```json
GET /my-index/_search
{
  "_source": ["title", "date"],
  "query": { "match_all": {} }
}
```

### Tip 7: Set Appropriate Mapping

Don't rely on dynamic mapping for production. Explicitly define field types, analyzers, and multi-fields.

### Tip 8: Use Aliases for Zero-Downtime Reindex

```json
POST /_aliases
{
  "actions": [
    { "remove": { "index": "old-index", "alias": "my-alias" } },
    { "add": { "index": "new-index", "alias": "my-alias" } }
  ]
}
```

### Tip 9: Monitor Shard Allocation

Set up alerts for unassigned shards, disk watermarks, and cluster health status.

### Tip 10: Use Read-Only Indices

For historical data that won't change:
```bash
PUT /logs-2023.01/_settings
{ "index.blocks.read_only": true }
```

### Tip 11: Profile Slow Queries

Always profile queries before optimizing. Use the `_profile` API to understand query execution.

### Tip 12: Use Doc Values

Doc values are more memory-efficient than fielddata for keyword and numeric fields. Avoid fielddata on text fields.

### Tip 13: Tune Thread Pools

```bash
# Check thread pool stats
GET /_cat/thread_pool?v&h=node_name,name,active,queue,rejected

# Adjust thread pool sizes in elasticsearch.yml
thread_pool.write.queue_size: 1000
```

### Tip 14: Use Snapshots for Backups

Never rely solely on file system backups. Use Elasticsearch snapshot API for consistent backups.

### Tip 15: Enable Slow Logs

Configure slow logs for search and indexing to identify performance bottlenecks.

### Tip 16: Use Keyword for Filtering

Use `keyword` type for fields used in filtering, aggregation, and sorting. Use `text` only for full-text search.

### Tip 17: Optimize Date Histograms

Use `calendar_interval` for regular intervals and `fixed_interval` for custom intervals.

### Tip 18: Use Template for Repeated Patterns

Define index templates for consistent mappings across multiple indices.

### Tip 19: Limit Query Depth

Avoid deeply nested queries. Use bool query with filter context for flat conditions.

### Tip 20: Monitor JVM Heap

Keep heap usage below 75%. Watch for GC pauses and increase heap if necessary.

---

## 19. Command Reference

### Cluster APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/_cluster/health` | Cluster health status |
| GET | `/_cluster/state` | Cluster state information |
| GET | `/_cluster/stats` | Cluster statistics |
| GET | `/_cluster/settings` | Cluster settings |
| PUT | `/_cluster/settings` | Update cluster settings |
| POST | `/_cluster/reroute` | Reroute shards |
| GET | `/_cluster/allocation/explain` | Explain shard allocation |
| GET | `/_cluster/pending_tasks` | Pending cluster tasks |
| POST | `/_cluster/voting_config_exclusions` | Add voting config exclusions |
| DELETE | `/_cluster/voting_config_exclusions` | Remove voting config exclusions |

### Node APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/_cat/nodes` | List nodes |
| GET | `/_nodes` | Node information |
| GET | `/_nodes/stats` | Node statistics |
| GET | `/_nodes/hot_threads` | Hot threads |
| GET | `/_cat/thread_pool` | Thread pool stats |
| GET | `/_cat/allocation` | Disk allocation |

### Index APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/<index>` | Create index |
| DELETE | `/<index>` | Delete index |
| GET | `/<index>` | Get index info |
| POST | `/_bulk` | Bulk operations |
| GET | `/<index>/_count` | Document count |
| GET | `/<index>/_stats` | Index statistics |
| GET | `/<index>/_settings` | Index settings |
| PUT | `/<index>/_settings` | Update settings |
| GET | `/<index>/_mapping` | Get mapping |
| PUT | `/<index>/_mapping` | Update mapping |
| POST | `/_refresh` | Refresh indices |
| POST | `/_flush` | Flush indices |
| POST | `/<index>/_forcemerge` | Force merge |
| POST | `/<index>/_shrink/<target>` | Shrink index |
| POST | `/<index>/_split/<target>` | Split index |
| POST | `/_aliases` | Manage aliases |
| POST | `/_reindex` | Reindex documents |

### Document APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/<index>/_doc/<id>` | Index document |
| POST | `/<index>/_doc` | Auto-generate ID |
| GET | `/<index>/_doc/<id>` | Get document |
| HEAD | `/<index>/_doc/<id>` | Check document exists |
| DELETE | `/<index>/_doc/<id>` | Delete document |
| POST | `/<index>/_doc/<id>/_update` | Update document |
| POST | `/_update_by_query` | Update by query |
| POST | `/_delete_by_query` | Delete by query |
| GET | `/<index>/_mget` | Multi-get |
| POST | `/_msearch` | Multi-search |
| POST | `/_mtermvectors` | Multi-term vectors |

### Search APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/<index>/_search` | Search |
| POST | `/<index>/_search` | Search (POST body) |
| GET | `/_search` | Search all |
| POST | `/_search/scroll` | Scroll search |
| GET | `/_search/point_in_time` | Create PIT |
| DELETE | `/_search/point_in_time` | Delete PIT |
| POST | `/_validate/query` | Validate query |
| GET | `/<index>/_explain/<id>` | Explain query |
| GET | `/<index>/_field_caps` | Field capabilities |

---

## 20. Configuration Reference

### elasticsearch.yml

```yaml
# ======================== Elasticsearch Configuration ========================

# Cluster
cluster.name: elasticsearch
cluster.initial_master_nodes: ["node-1", "node-2", "node-3"]

# Node
node.name: node-1
node.roles: [master, data, ingest, ml]

# Paths
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
path.repo: /mount/backups

# Network
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300
transport.compress: true

# Discovery
discovery.seed_hosts: ["node-2:9300", "node-3:9300"]
discovery.proactive_connect: true

# Memory
bootstrap.memory_lock: true

# Security
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.enabled: true
xpack.security.authc.realms.native.native1:
  order: 0

# Monitoring
xpack.monitoring.collection.enabled: true
xpack.monitoring.collection.interval: 10s

# Watcher
xpack.watcher.enabled: true

# ML
xpack.ml.enabled: true

# Snapshot
path.repo: ["/mount/snapshots"]

# CORS
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-methods: "OPTIONS, HEAD, GET, POST, PUT, DELETE"
http.cors.allow-headers: "X-Requested-With, Content-Type, Content-Length"

# Slow log
index.search.slowlog.threshold.query.warn: "10s"
index.search.slowlog.threshold.fetch.warn: "1s"
index.indexing.slowlog.threshold.index.warn: "10s"

# Thread pools
thread_pool.write.queue_size: 1000
thread_pool.search.queue_size: 1000
```

### jvm.options

```
## heap size
-Xms16g
-Xmx16g

## GC configuration
-XX:+UseG1GC
-XX:G1HeapRegionSize=4m
-XX:InitiatingHeapOccupancyPercent=30
-XX:G1ReservePercent=15

## G1GC Configuration
-XX:MaxGCPauseMillis=200
-XX:ParallelGCThreads=8
-XX:ConcGCThreads=4

## Optional gc logging
#-Xlog:gc*,gc+age=trace,safepoint:file=gc.log:utctime,pid,tags:filecount=32,filesize=64m

## Temporary directory
#-Djava.io.tmpdir=${ES_TMPDIR}

## Heap dumps
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/lib/elasticsearch/heapdump.hprof
```

### log4j2.properties

```properties
status = error
appender.console.type = Console
appender.console.name = console
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{ISO8601} [%t] %-5p %40C - %m%n

appender.rolling.type = RollingFile
appender.rolling.name = rolling
appender.rolling.fileName = ${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}.log
appender.rolling.layout.type = PatternLayout
appender.rolling.layout.pattern = %d{ISO8601} [%t] %-5p %40C - %m%n
appender.rolling.filePattern = ${sys:es.logs.base_path}${sys:file.separator}${sys:es.logs.cluster_name}-%d{yyyy-MM-dd}-%i.log.gz
appender.rolling.policies.type = Policies
appender.rolling.policies.time.type = TimeBasedTriggeringPolicy
appender.rolling.policies.time.interval = 1
appender.rolling.policies.size.type = SizeBasedTriggeringPolicy
appender.rolling.policies.size.size = 256MB

rootLogger.level = info
rootLogger.appenderRef.console.ref = console
rootLogger.appenderRef.rolling.ref = rolling
```

---

## 21. Real-World Examples

### Example 1: Centralized Logging

```json
// Index template for application logs
PUT /_index_template/app-logs
{
  "index_patterns": ["app-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "app-logs-policy"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "level": { "type": "keyword" },
        "service": { "type": "keyword" },
        "host": { "type": "keyword" },
        "message": { "type": "text" },
        "stack_trace": { "type": "text" },
        "request_id": { "type": "keyword" },
        "response_time": { "type": "integer" },
        "user_id": { "type": "keyword" },
        "url": { "type": "keyword" },
        "method": { "type": "keyword" },
        "status_code": { "type": "integer" }
      }
    }
  }
}

// Search for errors in last 24 hours
GET /app-logs-*/_search
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "level": "ERROR" } },
        { "range": { "@timestamp": { "gte": "now-24h" } } }
      ]
    }
  },
  "aggs": {
    "by_service": {
      "terms": { "field": "service", "size": 20 },
      "aggs": {
        "error_over_time": {
          "date_histogram": {
            "field": "@timestamp",
            "calendar_interval": "hour"
          }
        }
      }
    }
  }
}
```

### Example 2: E-Commerce Product Search

```json
// Product index
PUT /products
{
  "mappings": {
    "properties": {
      "name": {
        "type": "text",
        "analyzer": "english",
        "fields": {
          "keyword": { "type": "keyword" },
          "suggest": {
            "type": "completion",
            "analyzer": "simple"
          }
        }
      },
      "description": { "type": "text", "analyzer": "english" },
      "category": { "type": "keyword" },
      "price": { "type": "float" },
      "in_stock": { "type": "boolean" },
      "rating": { "type": "float" },
      "created_at": { "type": "date" }
    }
  }
}

// Search with facets
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "multi_match": {
          "query": "wireless headphones",
          "fields": ["name^3", "description"]
        }}
      ],
      "filter": [
        { "range": { "price": { "gte": 20, "lte": 100 } } },
        { "term": { "in_stock": true } }
      ]
    }
  },
  "aggs": {
    "categories": {
      "terms": { "field": "category" }
    },
    "price_ranges": {
      "histogram": {
        "field": "price",
        "interval": 25
      }
    },
    "avg_rating": {
      "avg": { "field": "rating" }
    }
  },
  "sort": [
    { "_score": "desc" },
    { "rating": "desc" }
  ]
}
```

### Example 3: Metrics Collection

```json
// Metrics index
PUT /metrics-{YYYY.MM.dd}
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "metric.name": { "type": "keyword" },
      "metric.value": { "type": "double" },
      "metric.tags": { "type": "object", "dynamic": true },
      "host": { "type": "keyword" },
      "service": { "type": "keyword" }
    }
  }
}

// Time-series query
GET /metrics-*/_search
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "term": { "metric.name": "cpu.usage" } },
        { "term": { "host": "web-server-1" } },
        { "range": { "@timestamp": { "gte": "now-1h" } } }
      ]
    }
  },
  "aggs": {
    "cpu_over_time": {
      "date_histogram": {
        "field": "@timestamp",
        "fixed_interval": "1m"
      },
      "aggs": {
        "avg_cpu": {
          "avg": { "field": "metric.value" }
        },
        "max_cpu": {
          "max": { "field": "metric.value" }
        }
      }
    }
  }
}
```

### Example 4: Security Event Analysis

```json
// Security events
PUT /security-events-{YYYY.MM.dd}
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "event_type": { "type": "keyword" },
      "severity": { "type": "keyword" },
      "source_ip": { "type": "ip" },
      "destination_ip": { "type": "ip" },
      "user": { "type": "keyword" },
      "action": { "type": "keyword" },
      "success": { "type": "boolean" },
      "geo": { "type": "geo_point" }
    }
  }
}

// Detect brute force attacks
GET /security-events-*/_search
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "term": { "event_type": "authentication" } },
        { "term": { "success": false } },
        { "range": { "@timestamp": { "gte": "now-1h" } } }
      ]
    }
  },
  "aggs": {
    "by_source_ip": {
      "terms": { "field": "source_ip", "size": 20 },
      "aggs": {
        "failed_count": {
          "value_count": { "field": "_id" }
        },
        "unique_users": {
          "cardinality": { "field": "user" }
        }
      }
    }
  }
}
```

### Example 5: Log Analytics Dashboard Queries

```json
// Error rate over time
GET /logs-*/_search
{
  "size": 0,
  "aggs": {
    "total_requests": {
      "date_histogram": {
        "field": "@timestamp",
        "calendar_interval": "hour"
      }
    },
    "error_requests": {
      "filter": { "term": { "level": "ERROR" } },
      "aggs": {
        "over_time": {
          "date_histogram": {
            "field": "@timestamp",
            "calendar_interval": "hour"
          }
        }
      }
    }
  }
}

// Top slow queries
GET /logs-*/_search
{
  "size": 10,
  "query": {
    "range": { "response_time": { "gte": 1000 } }
  },
  "sort": [
    { "response_time": "desc" }
  ],
  "_source": ["url", "method", "response_time", "@timestamp"]
}
```

---

## 22. Further Reading

### Official Documentation

- [Elasticsearch Reference](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Elasticsearch: The Definitive Guide](https://www.elastic.co/guide/en/elasticsearch/guide/current/index.html)
- [Elasticsearch Client API](https://www.elastic.co/guide/en/elasticsearch/client/index.html)

### Books

- *Elasticsearch in Action* by Radu Gidei, et al.
- *Elasticsearch 8.x Cookbook* by Alberto Paro
- *Mastering Elasticsearch* by Brett Rader, et al.

### Online Resources

- [Elastic Blog](https://www.elastic.co/blog)
- [Elastic Discuss Forums](https://discuss.elastic.co/)
- [Elastic GitHub](https://github.com/elastic/elasticsearch)
- [Elastic Slack Community](https://elasticstack.herokuapp.com/)

### Related Tools

- [Logstash](https://www.elastic.co/products/logstash) — Data processing pipeline
- [Kibana](https://www.elastic.co/products/kibana) — Visualization platform
- [Beats](https://www.elastic.co/beats) — Lightweight data shippers
- [APM](https://www.elastic.co/apm) — Application Performance Monitoring
- [Fleet](https://www.elastic.co/elastic-agent) — Centralized agent management
- [Elastic Agent](https://www.elastic.co/guide/en/fleet/current/index.html) — Unified agent

### Certifications

- Elasticsearch Certified Engineer
- Elastic Certified Analyst
- Elastic Certified Administrator

### Community

- [Elastic Community Projects](https://github.com/elastic)
- [Elastic User Groups](https://www.elastic.co/community)
- [Elastic{ON} Conference](https://www.elastic.co/elasticon)
