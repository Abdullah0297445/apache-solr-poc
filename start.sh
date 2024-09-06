#!/bin/bash

./create_collection.sh
./update_schema.sh
python solr_index.py
uvicorn solr_query:app --host 0.0.0.0 --port $SOLR_CLIENT_PORT --reload
