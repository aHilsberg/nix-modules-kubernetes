#!/usr/bin/env nu

def main [version: string] {
    http get --raw $"https://raw.githubusercontent.com/kubernetes/kubernetes/($version)/api/openapi-spec/swagger.json"
}