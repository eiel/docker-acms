https://registry.hub.docker.com/u/eiel/acms/

```
$ docker run -d --name my-mysql -e MYSQL_ROOT_PASSWORD="secret" mysql
$ docker run -d --name my-acms --link my-mysql:mysql -p 8002:80 -v `pwd`/acms:/var/www/html eiel/acms
```

* database_host: mysql
* database_user: root
* database_password: secret
* database_name: acms

After install, you move setup to _setup directory.
