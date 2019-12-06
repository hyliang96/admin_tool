# 集群批量管理工具

梁浩宇   hyliang96@163.com    hyliang96@github

## 介绍

这是一个批量管理集群的小工具

**功能**：

* 可以将机器编组

* 对一个组内每台机器并行地执行命令(一到多条、非交互式命令)，并按机器编号将每台机器的返回排序。

  包括不限于以下操作：

  * 显示所有gpu服务器的显卡使用情况
  * 在所有服务器上创建、查看、删除账号

**支持终端**：`zsh`或`bash`

**支持用户**: 普通用户和root用户

**原理**：并行ssh访问各台服务器

**性能：**经测试，查看所有gpu服务器的`gpustat`用时和`ansible -f 24` 几乎一样

**比ansible多的特性：**

* 会对各个服务器返回的结果进行排序
* 支持临时自定义机器编组
* 支持分发文件到机器编组
* 支持一键在机器编组创建用户

## 依赖

用户每一台机器上的 `/home/用户名/.ssh/{id_rsa,id_rsa.pub,authorized_keys}` 相同，其中`id_rsa.pub` 的全文已经加入到`authorized_keys` 中作为一行

* 若用户不满足此依赖，则他每次使用`all*` ,`send`命令，都会要求给每一台服务器输入密码，**欲满足此依赖，请管理员运行**

  ```bash
  . <本目录>/load.sh
  # 如 . /mfs/haoyu/server_conf/ENV/serverENV/admin_tool/load.sh
  allnewkey [机器编组] <用户名>
  ```

  会重新生成（覆盖原有的）一对`/home/用户名/.ssh/{id_rsa,id_rsa.pub}`,将`id_rsa.pub` 的全文已经加入到`authorized_keys` 中，并分发到`机器编组`的各台服务器上。

* 上述`allnewkey` 在下文 `alladduser` 创建用户时会自动执行

* 系统 `/etc/ssh/ssh_config` 配置好了，在其文尾添加如下配置

  ```

  Host c* juncluster* g* jungpu*
      StrictHostKeyChecking no

  Host c1 juncluster1
      HostName xxx.xxx.xxx.xxx
      IdentityFile ~/.ssh/id_rsa

  Host c2 juncluster2
      HostName xxx.xxx.xxx.xxx
      IdentityFile ~/.ssh/id_rsa

  ...
  ```

## 机器编组

### 编组写法

在下述众多命令中`[机器编组]`，均有两种写法

- 预置编组：即`./hosts.sh`中`server_sets`数组当中包含的编组，例如

  ```
  all c 'ls /home/$USER'
  ```

- 临时编组：`[机器编组]`写成`'服务器名 服务器名 服务器前缀{起始编号..结束编号} 服务器前缀{起始编号..结束编号}'`，（因此可以只写一台服务器名），例如

  ```
  alladduser 'g1 c2 jungpu{13..15} juncluster{3..4}'
  alladduser 'g1'
  ```

### 预置编组

| 预置编组名 | 服务器                    | 所在局域网 |
| ---------- | ------------------------- | ---------- |
| c          | juncluster1-4             | JUN1       |
| gJ1        | jungpu1-13                | JUN1       |
| J1         | juncluster1-4, jungpu1-13 | JUN1       |
| gJ2, J2    | jungpu14-24               | JUN2       |
| g          | jungpu1-24                | JUN1和JUN2 |
| a          | juncluster1-4, jungpu1-24 | JUN1和JUN2 |

本包使用`./hosts.sh`文件来配置预置编组，写法如下

```bash
# 顺序编组
# 编组名=(前缀{起始数字..结束数字}后缀)
c=(juncluster{1..4})
gJ1=(jungpu{1..13})
gJ2=(jungpu{14..24})

# 复合编组
# 编组名=( "${子编组1[@]}" "${子编组2[@]}" "${子编组3[@]}" )
g=( "${gJ1[@]}" "${gJ2[@]}" )
J1=( "${c[@]}" "${gJ1[@]}" )
J2=( "${gJ2[@]}" )
a=( "${c[@]}" "${g[@]}" )

# 有效编组：即只有写在此处的编组才会被 `all` 命令使用
server_sets=(c  g  gJ1  gJ2 J1 J2 a )
```

## 使用方法

### 加载本工具包

使用工具包前，需先在`zsh`或`bash`下执行以下命令

```bash
. <本目录>/load.sh
# 如 . /mfs/haoyu/server_conf/ENV/serverENV/admin_tool/load.sh
```

### 执行命令

对一个组内每台机器并行地执行命令

```bash
all [机器编组] '命令1' '命令2' '命令3' # 编组不可缺省，用单引号表示不转义，用双引号表示要不转义
```

* 可以执行一到多条命令
* 只能执行非交互式命令
* 返回：按机器编号将每台机器的返回排序

例如，

```bash
all c 'echo yes'
```

> ```
> echo yes
> ====== juncluster1 ======
> # echo yes
> yes
>
> ====== juncluster2 ======
> # echo yes
> yes
>
> ====== juncluster3 ======
> # echo yes
> yes
>
> ====== juncluster4 ======
> # echo yes
> yes
> ```

### 查看gpu使用

```bash
allgpu [机器编组]
```

编组可以缺省，默认编组为所有gpu服务器

### 用户管理

```bash
sudo su # 然后输入密码
. <本目录>/load.sh # 加载工具包
```

#### 创建用户

##### 先确认可用的uid

S1：输出本机`/etc/passwd`中的用户，按照uid降序排列，显示前n个用户名及其uid。若n缺省，则全显示

```
uids [n]
```

选择一个未被占用的uid=x

S2：确认uid=x, gui=x在所有机器上均未被占用

```bash
alluid [机器编组 缺省为a] [x]  # 查询各台服务器uid和gid是否被x占用
allgid [机器编组 缺省为a] [x]  # 查询各台服务器gid是否被x占用
```

返回如下则未被占用

> ```
> uid [x] available
> ```

返回如下(x=11111)则uid=x和gid=x均被占用，会把所有占用此uid的服务器和用户名显示出来

> ```
> uid 11111 not available
> gid 11111 not available
> jungpu12:     uid=11111(fixmfs) gid=11111(fixmfs) groups=11111(fixmfs)     group fixmfs:x:11111:
> jungpu13:     uid=11111(fixmfs) gid=11111(fixmfs) groups=11111(fixmfs)     group fixmfs:x:11111:
> ```

##### 交互界面，使用明码设置用户密码

* 生成随机明码用户密码

  ```bash
  openssl rand -base64 24 # 64位电脑，长为24的随机字符串；此加密方式及linux系统的用户密码加密方式
  ```

  > ```
  > iFLIklLJejU1uQ1U/V81m0mbXvQbOu9O
  > ```

* 将此明码复制下来以供后面设置

  设置一整个编组

  ```bash
  alladduser [用户名]@[机器编组]
  ```

  交互界面

  > ```
  > set realname: 用户真名，可以输入中文、英文字母、数字、空格、连字符、下划线
  > set uid: 集群上的uid要统一 以便mfs权限正确
  > set password: 明码用户密码
  > check password: 明码用户密码
  > ```

  自动在每一台服务器上开始创建账号，并为用户每一台机器上，创建相同的 `/home/用户名/.ssh/{id_rsa,id_rsa.pub,authorized_keys}` ，其中`id_rsa.pub` 的全文已经加入到`authorized_keys` 中作为一行

##### 非交互命令，使用加密的用户密码

设置一整个编组

```bash
alladduser  [用户名]@[机器编组]  '用户真名' 统一的UID '加密用户密码' # 要用单引号，表示不转义
```

自动在每一台服务器上开始创建账号，并为用户每一台机器上，创建相同的 `/home/用户名/.ssh/{id_rsa,id_rsa.pub,authorized_keys}` ，其中`id_rsa.pub` 的全文已经加入到`authorized_keys` 中作为一行

其中`统一的UID` `加密用户密码`有两种获得方式：

* 当已经在一些机器上创建了这个用户的账号时，为了使得其他机器新建账号的UID和用户密码，与旧机器上的一致，需要用本法设置：

  * UID：在旧机器上

    ```bash
    id 用户名
    ```

    > ```
    > uid=11328(用户名) gid=11328(当前组名) groups=11328(组名1) groups=12312(组名2)
    >     	↑                ↑                         ↑             ↑
    > 此即用户的UID       户当前组的GID	               用户所属所有组的GID
    > ```

    用上述方法初创用户时，用户的 组名, 群名 与 用户名 相同，用户的 gid, groups 与 uid 相同

  * 加密用户密码：在旧机器上

    ```bash
    sudo cat /etc/shadow | grep 用户名
    ```

    > ```
    > 用户名:$6$xDasasdSDsS1$hJNcEpsSDdP23SosSdzs.j3rHFToIHIH878bsS3w/fyVgnRnZ4/sdasisUlf7AA/3K1ENIJ2asiIIdsd9sSCxxgFsdSAQPa.:17266:0:99999:7:::
    > ```

    以冒号分隔，其中第二字段`$6$xDasasdSDsS1$hJNcEpsSDdP23SosSdzs.j3rHFToIHIH878bsS3w/fyVgnRnZ4/sdasisUlf7AA/3K1ENIJ2asiIIdsd9sSCxxgFsdSAQPa. ` 即加密用户密码

* 当明码用户密码已经知道时，还可以这样获得加密用户密码

  ```bash
  echo 明码用户密码 | openssl passwd -1 -stdin # 加密用户密码
  ```


### 查看用户

```bash
all [机器编组] 'id 用户名'        # 看看是否uid一致
all [机器编组] 'ls /home/用户名'  # 看看是否用户目录创建成功
ssh 用户名@jungpu1  # 看看能否正常登陆，使用前面设置的明码
```

### 修改用户UID

```bash
all [机器编组]  'usermod -u 用户UID 用户名 && groupmod -g 组GID 用户对应的组名'
```

获得`UID`和`GID` 需执行 `id 用户名`，详见上文

### 修改用户密码

* 修改单机密码

```bash
sudo passwd 用户名
```

* 修改多机密码

```bash
allpasswd 用户名@编组名                 # 交互界面下重新设定密码
 # 或
allpasswd 用户名@编组名 某台服务器名    # 一整个编组都使用这台服务器的密码
```

获得`加密密码` 需执行`sudo cat /etc/shadow | grep 用户名`，详细见上文

### 修改用户默认shell

```bash
all [机器编组] 'cat /etc/passwd | grep 用户名'  # 看看是否用户目录创建成功
```

> ```
> [用户名]:x:[用户UID]:[组GID]:,,,:/home/用户名:[默认shell路径]
> ```

`[默认shell路径]`如 `/usr/bin/zsh` 或 `/bin/bash` 或 (空的)

如果是空的，则为`/bin/sh`，极其难用，且用户自己无法修改默认shell

> ```
> chsh -s `which zsh`
> You may not change the shell for '用户名'.
> ```

```bash
all [机器编组] 'usermod -s [默认shell路径] [用户名]'
```

### 删除用户

请务必检查用户名，**谨慎操作**，删除不可逆

使用封装的命令

```bash
alldeluser [用户名]@[机器编组]     # 执行的是 'userdel -r 用户名', 注销账号，并删除/home/用户名、var/mail/用户名
```

或使用原始命令

```bash
all [机器编组] 'userdel -r 用户名'   # 注销账号，并删除/home/用户名、var/mail/用户名
all [机器编组] 'userdel 用户名'   # 注销账号，不删除/home/用户名、var/mail/用户名
```

### 分发文件

使用 `rsync` 进行分发

```bash
send 本地文件(夹)1 (本地文件(夹)2 ...) [机器编组]:接受文件夹的路径 # 不能加更多rsync的参数
```

* `本地文件夹` 表示发送得到 `接受文件夹的路径/本地文件夹` 整个文件夹，其中所有文件都保留，包括隐藏文件、软连接、硬链接，并保持文件(夹)所有者/组等特性

* `本地文件夹/` 表示发送得到 `接受文件夹的路径/本地文件夹下的所有文件（包括隐藏文件）

  **因此不要轻易加`/`，避免其下文件都混到下`接受文件夹的路径`下**

* `本地文件夹/*` 表示发送得到 `接受文件夹的路径/本地文件夹下的所有非隐藏文件`

* `本地文件夹/.*` 表示发送得到 `接受文件夹的路径/本地文件夹下的所有隐藏文件`

# 服务器其他管理命令

### 启动mfs

当服务器重启后，`/mfs` 没有挂载，请输入

```bash
mfsstart
```

以挂载`/mfs` 。它会区分当前服务器是JUN1还是JUN2，JUN1采用mfs挂载，JUN2采用sshfs挂载JUN1中的某台服务器上的`/mfs`。
