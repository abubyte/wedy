#!/bin/bash

# Wedy Development Environment Setup Script
# This script sets up the complete development environment

set -e  # Exit on any error

echo "🚀 Setting up Wedy development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the project root
if [ ! -f "docker-compose.yml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Check prerequisites
print_status "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.11+ first."
    exit 1
fi

# Check Poetry
if ! command -v poetry &> /dev/null; then
    print_warning "Poetry is not installed. Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
    export PATH="$HOME/.local/bin:$PATH"
fi

# Check Flutter (optional)
if ! command -v flutter &> /dev/null; then
    print_warning "Flutter is not installed. You'll need it for mobile development."
    print_warning "Install Flutter from: https://flutter.dev/docs/get-started/install"
fi

print_success "Prerequisites check completed!"

# Setup environment variables
print_status "Setting up environment variables..."

if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cp .env.example .env
    print_warning "Please edit .env file with your actual configuration values"
else
    print_warning ".env file already exists. Skipping..."
fi

# Setup backend environment
if [ ! -f "backend/.env" ]; then
    print_status "Creating backend .env file..."
    cp backend/.env.example backend/.env
    print_warning "Please edit backend/.env file with your configuration"
else
    print_warning "Backend .env file already exists. Skipping..."
fi

print_success "Directory structure created!"

# Setup Docker development environment
print_status "Setting up Docker development environment..."

# Stop any existing containers
print_status "Stopping any existing containers..."
docker-compose down --remove-orphans 2>/dev/null || true

# Pull latest images
print_status "Pulling latest Docker images..."
docker-compose pull

# Start services
print_status "Starting PostgreSQL and Redis..."
docker-compose up -d postgres redis

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check if PostgreSQL is ready
print_status "Checking PostgreSQL connection..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker-compose exec -T postgres pg_isready -U dev -d wedy_dev >/dev/null 2>&1; then
        print_success "PostgreSQL is ready!"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "PostgreSQL failed to start after $max_attempts attempts"
        exit 1
    fi
    
    print_status "Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
    sleep 2
    ((attempt++))
done

# Check if Redis is ready
print_status "Checking Redis connection..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
        print_success "Redis is ready!"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "Redis failed to start after $max_attempts attempts"
        exit 1
    fi
    
    print_status "Waiting for Redis... (attempt $attempt/$max_attempts)"
    sleep 2
    ((attempt++))
done

print_success "Docker services are running!"

# Setup Backend
print_status "Setting up backend..."
cd backend

# Install Python dependencies
print_status "Installing Python dependencies..."
poetry install

# Initialize database
print_status "Initializing database..."
poetry run python scripts/init_db.py

# Seed sample data
print_status "Seeding sample data..."
poetry run python scripts/seed_data.py

cd ..

print_success "Backend setup completed!"

# Setup Mobile (if Flutter is available)
if command -v flutter &> /dev/null; then
    print_status "Setting up mobile development..."
    cd mobile
    
    # Get Flutter dependencies
    print_status "Getting Flutter dependencies..."
    flutter pub get
    
    # Analyze code
    print_status "Analyzing Flutter code..."
    flutter analyze || print_warning "Flutter analyze found some issues"
    
    cd ..
    print_success "Mobile setup completed!"
else
    print_warning "Skipping mobile setup (Flutter not installed)"
fi

# Create helpful scripts
print_status "Creating helpful development scripts..."

# Backend start script
cat > scripts/dev/start-backend.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Wedy backend..."
cd backend
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
EOF

chmod +x scripts/dev/start-backend.sh

# Mobile start scripts
cat > scripts/dev/start-client-app.sh << 'EOF'
#!/bin/bash
echo "📱 Starting Wedy client app..."
cd mobile
flutter run --target lib/apps/client/main.dart
EOF

chmod +x scripts/dev/start-client-app.sh

cat > scripts/dev/start-merchant-app.sh << 'EOF'
#!/bin/bash
echo "📱 Starting Wedy merchant app..."
cd mobile
flutter run --target lib/apps/merchant/main.dart
EOF

chmod +x scripts/dev/start-merchant-app.sh

# Database reset script
cat > scripts/dev/reset-database.sh << 'EOF'
#!/bin/bash
echo "🗄️ Resetting Wedy database..."
cd backend
poetry run python scripts/init_db.py
poetry run python scripts/seed_data.py
echo "✅ Database reset completed!"
EOF

chmod +x scripts/dev/reset-database.sh

# Logs script
cat > scripts/dev/show-logs.sh << 'EOF'
#!/bin/bash
echo "📋 Showing Docker logs..."
docker-compose logs -f
EOF

chmod +x scripts/dev/show-logs.sh

print_success "Development scripts created!"

# Final status check
print_status "Performing final status check..."

# Check database connection from host
print_status "Testing database connection from host..."
if PGPASSWORD=devpass psql -h localhost -U dev -d wedy_dev -c "SELECT 1;" >/dev/null 2>&1; then
    print_success "Database connection from host: OK"
else
    print_warning "Database connection from host: Failed (this is normal if psql is not installed)"
fi

# Check Redis connection from host
print_status "Testing Redis connection from host..."
if redis-cli -h localhost -p 6379 ping >/dev/null 2>&1; then
    print_success "Redis connection from host: OK"
else
    print_warning "Redis connection from host: Failed (this is normal if redis-cli is not installed)"
fi

# Display final information
echo ""
echo "🎉 Wedy development environment setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env and backend/.env files with your configuration"
echo "2. Start the backend: ./scripts/dev/start-backend.sh"
echo "3. Open API docs: http://localhost:8000/docs"
echo "4. Start mobile apps: ./scripts/dev/start-client-app.sh"
echo ""
echo "🔧 Available services:"
echo "• Backend API: http://localhost:8000"
echo "• API Documentation: http://localhost:8000/docs"
echo "• pgAdmin: http://localhost:5050 (admin@wedy.uz / admin123)"
echo "• Redis Commander: http://localhost:8081"
echo ""
echo "📱 Mobile development:"
echo "• Client app: ./scripts/dev/start-client-app.sh"
echo "• Merchant app: ./scripts/dev/start-merchant-app.sh"
echo ""
echo "🛠️ Useful commands:"
echo "• Reset database: ./scripts/dev/reset-database.sh"
echo "• Show logs: ./scripts/dev/show-logs.sh"
echo "• Stop services: docker-compose down"
echo ""
echo "Happy coding! 🚀"