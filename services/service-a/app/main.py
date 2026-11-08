from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"name": "service-a", "status": "active", "message": "SERVICE A SAYS HELLO"}


