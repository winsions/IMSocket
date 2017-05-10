//
//  ViewController.m
//  02.客户端
//
//  Created by 1 on 16/1/30.
//  Copyright © 2016年 xiaomage. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

/** 客户端的Socket */
@property (nonatomic ,strong) GCDAsyncSocket *clientSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

//与服务器连接
- (IBAction)connectToHost:(id)sender {
 
    // 1.创建一个socket对象
    if (self.clientSocket == nil) {
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    // 2.连接服务器
    NSError *error = nil;
//    [self.clientSocket connectToHost:@"10.62.27.92" onPort:9091 error:&error];
    [self.clientSocket connectToHost:@"119.23.248.224" onPort:9091 error:&error];
    
//    [self.clientSocket connectToHost:@"192.168.239.138" onPort:9091 error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    
}

// 与服务器连接成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{

    self.statusLabel.text = @"连接中..";
    self.statusLabel.backgroundColor = [UIColor greenColor];
    
#warning 读取数据
    [sock readDataWithTimeout:-1 tag:0];
}

// 与服务器连接断开
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"%@",err);
    self.statusLabel.text = @"断开..";
    self.statusLabel.backgroundColor = [UIColor redColor];
}

// 与服务器断开
- (IBAction)closeToHost:(id)sender {
    [self.clientSocket disconnect];
}

// 发图片
- (IBAction)sendImag:(id)sender {
    
    // 把图片转在NSData
    UIImage *img = [UIImage imageNamed:@"IMG_2427.JPG"];
    NSData *imgData = UIImagePNGRepresentation(img);

    
    //定义数据格式传输协议
    //请求头和请求体 / 响应头和响应体
    
    NSMutableData *totalDataM = [NSMutableData data];
    
    // 1.拼接长度(0~3:长度)
    unsigned int totalSize = 4 + 4 + (int)imgData.length;
    NSData *totalSizeData = [NSData dataWithBytes:&totalSize length:4];
   
    

    [totalDataM appendData:totalSizeData];
    
    // 2.拼接指令类型(4~7:指令)
    // 0x00000001 = 图片
    // 0x00000002 = 文字
    // 0x00000003 = 位置
    // 0x00000004 = 语音
    unsigned int commandId = 0x00000001;
    NSData *commandIdData = [NSData dataWithBytes:&commandId length:4];
    [totalDataM appendData:commandIdData];
    
    // 3.拼接图片(8~N) 图片数据
    [totalDataM appendData:imgData];
    NSLog(@"图片的字节大小:%ld",imgData.length);
    NSLog(@"发送数据的总字节大小:%ld",totalDataM.length);
    
    // 发数据
    
    [self.clientSocket writeData:totalDataM withTimeout:-1 tag:0];
}


- (IBAction)sendText:(id)sender {
    
    
    NSString *text = @"Hello,自定义协议";
    NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *totalDataM = [NSMutableData data];
    
    // 1.拼接长度(0~3:长度)
    unsigned int totalSize = 4 + 4 + (int)textData.length;
    
    NSData *totalSizeData = [NSData dataWithBytes:&totalSize length:4];
//    NSString *string = [[NSString alloc] initWithFormat:@"%d",totalSize];
//    NSData *totalSizeData = [NSData dataWithBytes:&string length:4];

    NSLog(@"%@",totalSizeData);
    [totalDataM appendData:totalSizeData];
    
    // 2.拼接指令类型(4~7:指令)
    // 0x00000001 = 图片
    // 0x00000002 = 文字
    // 0x00000003 = 位置
    // 0x00000004 = 语音
    unsigned int commandId = 0x00000002;
    NSData *commandIdData = [NSData dataWithBytes:&commandId length:4];
    [totalDataM appendData:commandIdData];
    
    // 3.拼接(8~N) 文字数据
    [totalDataM appendData:textData];
    NSLog(@"发送数据的总字节大小:%ld",textData.length);
     NSLog(@"%@",totalDataM);
    //发送
    [self.clientSocket writeData:totalDataM withTimeout:-1 tag:0];
    
    
}

// 接收服务器响应的数据
-(void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag{


    NSLog(@"%@",data);
    NSData *totalSizeData = [data subdataWithRange:NSMakeRange(0, 4)];
    unsigned int totalSize = 0;
    [totalSizeData getBytes:&totalSize length:4];
    NSLog(@"响应总数据的大小 %u",totalSize);
    
    // 获取指令类型
    NSData *commandIdData = [data subdataWithRange:NSMakeRange(4, 4)];
    unsigned int commandId = 0;
    [commandIdData getBytes:&commandId length:4];
    
    // 结果
    NSData *resultData = [data subdataWithRange:NSMakeRange(8, 4)];
    unsigned int result = 0;
    [resultData getBytes:&result length:4];
    
    
    NSMutableString *str = [NSMutableString string];
    if (commandId == 0x00000001) {//图片
        [str appendString:@"图片 "];
    }else if(commandId == 0x00000002){//文字
        [str appendString:@"文字 "];
    }
    
    
    if(result == 1){
        [str appendString:@"上传成功"];
    }else{
        [str appendString:@"上传失败"];
    }
    
    NSLog(@"%@",str);
    
    
#warning 可以接收下一次数据
    [clientSocket readDataWithTimeout:-1 tag:0];
    
}


@end
