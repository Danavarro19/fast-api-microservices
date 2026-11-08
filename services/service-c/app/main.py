from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
def health():
    return {"name": "service-c", "status": "active", "message": "SERVICE C SAYS HELLO DEAR"}
