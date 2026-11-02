from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"name": "service-a", "status": "active", "message": "What is going on here?!"}


