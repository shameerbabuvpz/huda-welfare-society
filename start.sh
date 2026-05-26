#!/bin/bash
cd backend
npm run migrate || echo "Migration skipped or failed"
npm start
