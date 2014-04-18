# Lambda Dashboard: BigQuery

## BigQuery for historical rps chart
```
SELECT
  STRFTIME_UTC_USEC(time * 1000000, "%Y-%m-%d %H:%M") as tstamp, 
  count(*) / 60 as rps 
FROM gcp_samples.nginx0,gcp_samples.nginx1,gcp_samples.nginx2
GROUP BY tstamp ORDER BY tstamp DESC;
```

# Lambda Dashboard: Norikra CEP

## Add Norikra server

* Create GCE instance
* Run Docker image for Norikra
```
sudo docker run -p 26578:26578 -p 26571:26571 -p 24224:24224 -p 24224:24224/udp -e GAS_URL=https://script.google.com/macros/s/AKfycbzHIhSB6Gm-b7Ix7Sc1aE0EpjsJTpwnWqcyYbr8LCLTU0CTSLy4/exec -t -i -d kazunori279/fluentd-norikra-gas
```
* See Norikra UI on browser

## Add GCE instance for nginx

* Create GCE instance
* Run Docker image for nginx
```
NORIKRA_IP=<<Norikra server internal IP>>
sudo docker run -e NORIKRA_IP=$NORIKRA_IP -p 80:80 -t -i -d kazunori279/fluentd-nginx
```
* See nginx welcome page on browser

## Run Apache Bench

```
NGINX_IP=<<nginx server external IP>>
ab -c 5 -n 1000000 http://NGINX_IP/
```

## Query for rps
```
select sum(count) / 15 as rps 
from nginx_count_access.win:time(15 sec) 
output snapshot every 3 sec
```

## Query for number of hosts
```
select count(distinct dstat.hostname) as hosts
from dstat.win:time(15 sec) 
output snapshot every 3 sec
```

## Query for CPU stats
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

# Lambda Dashboard: Large Deployment

## Add Load Balancing
```
gcutil addtargetpool "nginx" --region="us-central1"
gcutil addforwardingrule "nginx" --region="us-central1" --target="nginx"
```

## Add nginx (2 core x 70)
```
echo nginx{0..69} > nginx_hosts

gcutil addinstance \
  --zone="us-central1-b" \
  --machine_type="n1-standard-2" \
  --image="https://www.googleapis.com/compute/v1/projects/gcp-samples/global/images/backports-debian-7-wheezy-v20140318-docker-0-9-0" \
  --service_account_scopes="https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/bigquery" \
  --metadata=startup-"script:sudo docker run -e NORIKRA_IP=$NORIKRA_IP -p 80:80 -t -i -d kazunori279/fluentd-nginx-bq" \
  $(cat nginx_hosts)

gcutil addtargetpoolinstance nginx \
  --region="us-central1" \
  --instances="$(cat nginx_hosts | sed -e 's/\(\w*\)/us-central1-b\/instances\/\1,/g' | sed -e 's/\(.*\),/\1/')"
```

## Add Apache Bench (2 core x 20)
```
echo ab{0..19} > ab_hosts

gcutil addinstance \
  --zone="us-central1-b" \
  --machine_type="n1-standard-2" \
  --image="https://www.googleapis.com/compute/v1/projects/gcp-samples/global/images/backports-debian-7-wheezy-v20140318-docker-0-9-0" \
  --service_account_scopes="https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control" \
  --metadata=startup-"script:sudo docker run -t -i -d kazunori279/ab ab -c 500 -n 10000000 http://$NGINX_IP/" \
  $(cat ab_hosts)
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



