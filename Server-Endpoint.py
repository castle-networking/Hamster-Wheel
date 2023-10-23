from fastapi import FastAPI
from pydantic import BaseModel
import json

app = FastAPI()

class DiskInfo(BaseModel):
    total: str
    used: str
    free: str

class Services(BaseModel):
    http: bool
    ssh: bool
    postgress: bool
    ignition: bool

class Connection(BaseModel):
    database: bool
    ignition: bool
    dolos: bool
    pointer: bool
    pointforword: bool

class Data(BaseModel):
    hostname: str
    cpu: float
    memory: float
    uptime: str
    ip: str
    disks: dict
    services: Services
    connection: Connection

@app.post("/receive_data")
async def receive_data(data: Data):
    # Load existing data from the JSON file
    existing_data = []
    with open("data.json", "r") as file:
        for line in file:
            existing_data.append(json.loads(line))

    # Find and update data for the same hostname or add new data
    updated_data = [data.dict()]  # Default to the new data
    for existing in existing_data:
        if existing["hostname"] == data.hostname:
            continue  # Skip the existing data with the same hostname
        updated_data.append(existing)

    # Save the updated data to the JSON file
    with open("data.json", "w") as file:
        for d in updated_data:
            json.dump(d, file)
            file.write('\n')

    return {"message": "Data received and saved successfully"}

@app.get("/get_data/{hostname}")
async def get_data(hostname: str):
    # Retrieve the most recent data for a specific hostname
    recent_data = None
    with open("data.json", "r") as file:
        for line in file:
            data = json.loads(line)
            if data["hostname"] == hostname:
                recent_data = data

    if recent_data:
        return {"data": recent_data}
    else:
        return {"message": "Data not found for the specified hostname"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
