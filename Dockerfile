FROM python:3.12

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY solr_index.py .
COPY solr_query.py .

COPY scripts/ scripts/
RUN find scripts -name *.sh -type f -exec sed -i 's/\r\n$/\n/g' {} \; -exec chmod +x {} \;

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
