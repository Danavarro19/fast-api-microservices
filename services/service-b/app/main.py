from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
def health():
    return {"name": "service-b", "status": "active", "message": "SERVICE B SAYS HELLO THERE"}


