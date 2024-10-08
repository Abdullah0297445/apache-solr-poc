#!/bin/bash

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":[
    {
      "name":"subject",
      "type":"text_general",
      "stored":true,
      "indexed":true
    },
    {
      "name":"content",
      "type":"text_general",
      "stored":true,
      "indexed":true
    },
    {
      "name":"published_at",
      "type":"pdate",
      "stored":true,
      "indexed":true
    },
    {
      "name":"tags.tag_category",
      "type":"text_general",
      "stored":true,
      "indexed":true,
      "multiValued":true
    },
    {
      "name":"tags.tag_aliases",
      "type":"text_general",
      "stored":true,
      "indexed":true,
      "multiValued":true
    },
    {
      "name":"related_tags.related_tag_category",
      "type":"text_general",
      "stored":true,
      "indexed":true,
      "multiValued":true
    },
    {
      "name":"related_tags.related_tag_aliases",
      "type":"text_general",
      "stored":true,
      "indexed":true,
      "multiValued":true
    }
  ]
}' "http://$SOLR_HOST:$SOLR_PORT/solr/$SOLR_COLLECTION_NAME/schema"

echo "Solr schema fields added successfully!"
