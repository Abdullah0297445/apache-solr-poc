import os
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
import pysolr

app = FastAPI()

SOLR_URL = f'http://{os.getenv("SOLR_HOST")}:{os.getenv("SOLR_PORT")}/solr/{os.getenv("SOLR_COLLECTION_NAME")}'
solr = pysolr.Solr(SOLR_URL, always_commit=True)


class SearchResult(BaseModel):
    id: str
    subject: list[str]
    content: list[str]
    published_at: str
    score: float


@app.get("/search", response_model=list[SearchResult])
async def search(q: str = Query(..., description="Search query")):
    query = (
        f'subject:({q}) OR content:({q}) OR tags.tag_category:({q}) OR tags.tag_aliases:({q}) OR '
        f'related_tags.related_tag_category:({q}) OR related_tags.related_tag_aliases:({q})'
    )

    try:
        # Execute the Solr query
        results = solr.search(query, **{
            'fl': 'id,subject,content,published_at,score',
            'rows': 20,
            'sort': 'score desc'
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Solr query failed: {str(e)}")

    return results
