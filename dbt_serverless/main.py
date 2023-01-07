import logging
from os import environ
from subprocess import Popen, PIPE, STDOUT

from fastapi import FastAPI
import yaml

app = FastAPI()

ENV = environ.get("DBT_ENV", "dev")

PROFILES_DIR = "--profiles-dir ."

DEBUG_COMMAND = f"dbt debug {PROFILES_DIR}"
RUN_COMMAND = f"dbt run {PROFILES_DIR} -t {ENV}"
DEPS_COMMAND = f"dbt deps"


@app.on_event("startup")
async def startup_event():
    with open("config.yml") as f:
        config = yaml.load(f, Loader=yaml.FullLoader)
        logging.config.dictConfig(config)


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/deps")
async def deps():
    return execute_and_log_command(DEPS_COMMAND)


@app.get("/debug")
async def debug():
    return execute_and_log_command(DEBUG_COMMAND)


@app.get("/run")
async def run():
    return execute_and_log_command(RUN_COMMAND)


def log_subprocess_output(pipe):
    count = 0
    for line in iter(pipe.readline, b""):  # b'\n'-separated lines
        if count > 200:
            break
        logging.info(line)
        count += 1


def execute_and_log_command(command: str) -> int:
    process = Popen(command, stdout=PIPE, stderr=STDOUT, shell=True)
    with process.stdout:
        log_subprocess_output(process.stdout)
    return process.wait()
