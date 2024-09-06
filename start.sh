#!/bin/bash

sleep 5
curl "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=$SOLR_COLLECTION_NAME&numShards=1&collection.configName=_default"
python solr_index.py
uvicorn solr_query:app --host 0.0.0.0 --port $SOLR_CLIENT_PORT --reload
