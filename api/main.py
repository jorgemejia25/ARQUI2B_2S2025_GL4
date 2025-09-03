from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"mensaje": "Hola, FastAPI está funcionando 🚀"}

@app.get("/saludo/{nombre}")
def saludar(nombre: str):
    return {"saludo": f"Hola {nombre}"}

@app.get("/ping")
def ping():
    return {"pong": True}
