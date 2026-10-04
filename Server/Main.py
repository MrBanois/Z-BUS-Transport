from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

#CRUDS
from CRUD.Department import router as dep_router
from CRUD.Position import router as pos_router
from CRUD.Route import router as route_router
from CRUD.User import router as user_router

#Auth
from Auth import router as auth_router

#Report
from Reports import router as report_router

app = FastAPI()

# The Flutter web build is served from a different origin than this API
# (localhost:<flutter port> vs localhost:8000), so the browser blocks every call
# without this. Origins are matched by regex rather than a "*" wildcard because
# allow_credentials and "*" are mutually exclusive in the CORS spec, and the
# login endpoint does need credentials. Loopback on any port is the dev case;
# add the deployed web origin here when there is one.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#Auth API
app.include_router(auth_router, prefix="/api", tags=["Authentication"])

#CRUD API
app.include_router(pos_router, prefix="/api", tags=["Permissions"])
app.include_router(user_router, prefix="/api", tags=["Users"])
app.include_router(dep_router, prefix="/api", tags=["Departments"])
app.include_router(route_router, prefix="/api", tags=["Routes"])

#Report API
app.include_router(report_router, prefix="/api", tags=["Report"])

@app.get("/api")
def Root() :
    return {"message" : "API is running "}

if __name__ == "__main__" :
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
