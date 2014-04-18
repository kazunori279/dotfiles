# Lambda Dashboard Demo

## Test with single Apache Bench instance

```
ab -c 5 -n 1000000 http://107.178.221.78/
```

## Norikra query for rps
```
select sum(count) / 15 as rps 
from nginx_count_access.win:time(15 sec) 
output snapshot every 3 sec
```

## Norikra query for number of hosts
```
select count(distinct dstat.hostname) as hosts
from dstat.win:time(15 sec) 
output snapshot every 3 sec
```

## Norikra query for CPU stats
```
select 
  avg(cast(dstat.dstat.total_cpu_usage.usr,double)) as usr, 
  avg(cast(dstat.dstat.total_cpu_usage.sys,double)) as sys, 
  avg(cast(dstat.dstat.total_cpu_usage.wai,double)) as wai, 
  avg(cast(dstat.dstat.total_cpu_usage.hiq,double)) as hiq, 
  avg(cast(dstat.dstat.total_cpu_usage.siq,double)) as siq 
from dstat.win:time(5 sec) 
output snapshot every 3 sec
```

## Test with 20 Apache Bench instance
```
echo ab{0..19} > ab_hosts

gcutil addinstance \
  --zone="us-central1-b" \
  --machine_type="n1-standard-2" \
  --image="https://www.googleapis.com/compute/v1/projects/gcp-samples/global/images/backports-debian-7-wheezy-v20140318-docker-0-9-0" \
  --service_account_scopes="https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control" \
  --metadata=startup-"script:sudo docker run -t -i -d kazunori279/ab ab -c 500 -n 10000000 http://107.178.221.78/" \
  $(cat ab_hosts)
```


# Setting up one Norikra server

## adding Norikra instance

```
gcutil addinstance \
  --zone="us-central1-b" \
  --machine_type="n1-standard-2" \
  --image="https://www.googleapis.com/compute/v1/projects/gcp-samples/global/images/backports-debian-7-wheezy-v20140318-docker-0-9-0" \
  --service_account_scopes="https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control" \
  --metadata=startup-"script:sudo docker run -p 26578:26578 -p 26571:26571 -p 24224:24224 -p 24224:24224/udp -e GAS_URL=https://script.google.com/macros/s/AKfycbzHIhSB6Gm-b7Ix7Sc1aE0EpjsJTpwnWqcyYbr8LCLTU0CTSLy4/exec -t -i -d kazunori279/fluentd-norikra-gas" \
  demo-norikra0
```

# Setting up Load Balancer and 70 nginx instances

## adding LB
```
gcutil addtargetpool "nginx" --region="us-central1"
gcutil addforwardingrule "nginx" --region="us-central1" --target="nginx"
```

## adding nginx instances
```
echo nginx{0..69} > nginx_hosts

gcutil addinstance \
  --zone="us-central1-b" \
  --machine_type="n1-standard-2" \
  --image="https://www.googleapis.com/compute/v1/projects/gcp-samples/global/images/backports-debian-7-wheezy-v20140318-docker-0-9-0" \
  --service_account_scopes="https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/bigquery" \
  --metadata=startup-"script:sudo docker run -e NORIKRA_IP=10.240.82.164 -p 80:80 -t -i -d kazunori279/fluentd-nginx-bq" \
  $(cat nginx_hosts)

gcutil addtargetpoolinstance nginx \
  --region="us-central1" \
  --instances="$(cat nginx_hosts | sed -e 's/\(\w*\)/us-central1-b\/instances\/\1,/g' | sed -e 's/\(.*\),/\1/')"
```

# Cleaning up

## deleting ab instances
```
cat ab_hosts | xargs -n1 -P $(cat ab_hosts | wc -w) gcutil deleteinstance -f --delete_boot_pd --zone="us-central1-b"
```

## deleting nginx instances

```
gcutil removetargetpoolinstance nginx \
  --region="us-central1" \
  --instances="$(cat nginx_hosts | sed -e 's/\(\w*\)/us-central1-b\/instances\/\1,/g' | sed -e 's/\(.*\),/\1/')"

cat nginx_hosts | xargs -n1 -P $(cat nginx_hosts | wc -w) gcutil deleteinstance -f --delete_boot_pd --zone="us-central1-b"
```



