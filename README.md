# NFL Superset Analytics

Apache Superset deployment for NFL analytics dashboards, connected to Supabase database.

## Deployment Instructions

### Prerequisites
- DigitalOcean droplet with Ubuntu 22.04
- Docker and Docker Compose installed
- SSH access configured

### Setup Steps

1. Clone this repository to your server
2. Create a `.env` file with your environment variables
3. Start the containers:docker compose up -d
4. Access Superset at http://your-server-ip:8088

### Environment Variables

See the `.env.example` file for required variables.

### Maintenance

- View logs: `docker compose logs -f`
- Restart services: `docker compose restart`
- Update application: `docker compose down && git pull && docker compose up -d --build`