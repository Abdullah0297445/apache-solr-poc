FROM python:3.12

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY solr_index.py .
COPY solr_query.py .

COPY start.sh .
RUN sed -i 's/\r\n$/\n/g' start.sh
RUN chmod +x start.sh

COPY entrypoint.sh .
RUN sed -i 's/\r\n$/\n/g' entrypoint.sh
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
