//
//  ViewController.m
//  Socket实现简单聊谈功能(TCP)
//
//  Created by MS on 15/9/11.
//  Copyright (c) 2015年 MS. All rights reserved.
//

#import "ViewController.h"
#import "AsyncSocket.h"
@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,AsyncSocketDelegate>
{
//    服务器端套接字对象，用于收发消息
    AsyncSocket *_serverSocket;
    
//    客户端套接字，用于收发消息
     AsyncSocket *_tcpSocket;
    
// 保存和服务器连接成功的客户端套接字对象
    NSMutableArray *_connectSocket;
    
    
}
//存储客户端发送过来的数据
@property (nonatomic, strong) NSMutableArray *dataArray;

//显示接收到的信息
@property (nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong)UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    self.automaticallyAdjustsScrollViewInsets = NO;
    
//   开辟空间用来保存用户交互
    self.dataArray = [[NSMutableArray alloc]init];
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-400) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
    
    
//
    _connectSocket = [[NSMutableArray alloc]init];
    
    
//   创建对象
//    1.服务器端
    _serverSocket = [[AsyncSocket alloc]initWithDelegate:self];
//    2.客户端
    _tcpSocket = [[AsyncSocket alloc] initWithDelegate:self];
    
//    3.服务器绑定端口号
    [_serverSocket acceptOnPort:9999 error:nil];
    
    //    4.和服务器连接
    //    (1)ip地址
    NSString *host = @"xzg.local";
    //    （2）端口号
    UInt16 port = 9999;
    //    （3）启动连接
    [_tcpSocket connectToHost:host onPort:port error:nil];
    
    
    
// UITextField 用于发送文字
    _textField = [[UITextField alloc]init];
    _textField.frame = CGRectMake(0, self.view.frame.size.height-400,self.view.frame.size.width,44);
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_textField];
    
//
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2.0 - 25, self.view.frame.size.height -350, 50, 44)];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn setTitle:@"发送" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(senderText:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
//    UIButton *btn1 = [[UIButton alloc]initWithFrame:CGRectMake(200, self.view.frame.size.height -350, 100, 44)];
//    [btn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
//    [btn1 setTitle:@"链接服务器" forState:UIControlStateNormal];
//    [btn1 addTarget:self action:@selector(LinkedServer:) forControlEvents:UIControlEventTouchUpInside];
//    [btn1 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    [self.view addSubview:btn1];
//    
    
}
#pragma mark -- 按钮点击事件
//发送数据
-(void)senderText:(id)btn
{
    if(![_tcpSocket isConnected]){
        NSLog(@"客户端未与服务器连接");
        return;
    }
    
    NSString *content = self.textField.text;
    [self.dataArray addObject:content];
    [self.tableView reloadData];
    
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    [_tcpSocket writeData:data withTimeout:60 tag:1000];
}

//-(void)LinkedServer:(id)btn
//{
//    //    4.和服务器连接
//    //    (1)ip地址
//    NSString *host = @"chenrr.local";
//    //    （2）端口号
//    UInt16 port = 9999;
//    //    （3）启动连接
//    [_tcpSocket connectToHost:host onPort:port error:nil];
//}


#pragma mark --UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}

#pragma mark -- AsyncSocketDelegate 

//==============服务器端==============
//当有人来链接我调用这个方法
-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
#warning 配合发送信息时必须使用以下方法
    //   从新链接服务器
    /*
    //    (1)ip地址
    NSString *host = @"xzg.local";
    //    （2）端口号
    UInt16 port = 9999;
    //    （3）启动连接
    [_tcpSocket connectToHost:host onPort:port error:nil];
   */
    
     NSLog(@"请求加为好友");
     [_connectSocket addObject:newSocket];
    // 接收连接客户端发过来数据 只是接收一次
    
    [newSocket readDataWithTimeout:-1 tag:300];
}
-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *content = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self.dataArray addObject:content];
    [self.tableView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataArray.count-1 inSection:0];

    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
     [sock readDataWithTimeout:-1 tag:300];
                            
}

//==============客户端==============
//连接服务器成功时回调的方法
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    
    NSLog(@"客户端连接服务器成功");
}

//连接服务器失败时回调的方法
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err{
    
    NSLog(@"%@",err);
}
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"客户端 表示发送完成了 肯定对方接收到了");
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
