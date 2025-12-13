FROM python:3.10 

WORKDIR /app

RUN pip install fastapi kubernetes
COPY autoheal-controller.py .

EXPOSE 8000

CMD ["python3", "autoheal-controller.py"]