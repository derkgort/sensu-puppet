# Sensu Backend URL's require protocol of ws:// or wss://.
# A port is also required.
# There is logic in sensugo::agent class to add the protocol so it's optional.
type Sensugo::Backend_URL = Variant[
  Pattern[/^[^\s:]+:\d+$/],
  Pattern[/^ws:\/\/[^\s:]+:\d+$/],
  Pattern[/^wss:\/\/[^\s:]++:\d+$/]
]
