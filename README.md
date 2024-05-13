# etcd_manage
etcd集群同时启动或暂停的脚本

1. 启动前提，
   1. etcd需要时systemd方式启动
   2. ssh免密
2. 修改主机和对应的属组
3. 启动和停止的日志就放在etcd.service指向的配置文件中的systemd_manage.log中
4. 执行启动和停止后，2秒后获取其状态
5. 执行获取状态后，立刻获取其状态
