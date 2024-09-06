#!/bin/bash

curl "http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=$SOLR_COLLECTION_NAME&numShards=1&collection.configName=_default"
