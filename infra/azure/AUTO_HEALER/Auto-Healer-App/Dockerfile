FROM python:3.10 

WORKDIR /app

RUN pip install fastapi kubernetes uvicorn
COPY autoheal-controller.py .

EXPOSE 8000

CMD ["uvicorn", "autoheal-controller:app", "--host", "0.0.0.0", "--port", "8000"]