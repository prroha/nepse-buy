#!/bin/sh
set -e

echo "🚀 Starting application..."

# Run database migrations
echo "📦 Running database migrations..."
npx prisma migrate deploy

# Run database seed (idempotent - won't duplicate data)
echo "🌱 Running database seed..."
npx prisma db seed || echo "⚠️  Seed skipped or already applied"

# Start the application
echo "✅ Starting server..."
exec node dist/app.js
