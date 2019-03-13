include ::sensugo::backend
class { '::sensugo::agent':
  backends => ['sensu-backend.example.com:8081']
}
