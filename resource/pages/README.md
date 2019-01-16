# error-pages
Error pages for [datarc.cn](https://datarc.cn).

#### Examples
* [404](https://r.datarc.cn/pages/404.html)
* [500](https://r.datarc.cn/pages/500.html)
* [503](https://r.datarc.cn/pages/503.html)

#### Nginx Config
```
error_page  404              /404.html;
location = /404.html {
    return 302 https://r.datarc.cn/pages/404.html;
}

error_page   500 502 503 504  /500.html;
location = /500.html {
    return 302 https://r.datarc.cn/pages/500.html;
}

error_page   503 /503.html;
location = /503.html {
    return 302 https://r.datarc.cn/pages/503.html;
}
```