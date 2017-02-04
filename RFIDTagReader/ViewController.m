//
//  ViewController.m
//  RFIDTagReader
//
//  Created by vingleo on 16/7/15.
//  Copyright © 2016年 Vingleo. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#import "ViewController.h"

static const short SERVER_PORT = 8600;
static const int MAX_Q_LEN = 64;
static const int MAX_MSG_LEN = 10;  //default value = 4096

@implementation ViewController

void change_enter_to_tail_zero(char * const buffer, int pos){
    for (int i = pos -1; i>=0;i--) {
        if (buffer[i]== '\r') {
            buffer[i] = '\0';
            break;
        }
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

-(BOOL)connection:(NSString *)hostText port:(int)port {
    int serverSocketFD = socket(AF_INET,SOCK_STREAM,0);
    if (serverSocketFD < 0) {
        perror("Could not create sokcet !!!\n");
        self.messageLabel.stringValue = @"Could not create sokcet !!!";
        exit(1);
    }
    struct sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    serverAddr.sin_addr.s_addr =inet_addr(hostText.UTF8String);
    
    int ret = bind(serverSocketFD, (struct sockaddr *)&serverAddr, sizeof serverAddr);
    
    if (ret < 0) {
        perror("无法将套接字绑定到指定的地址！！！\n");
        self.messageLabel.stringValue = @"无法将套接字绑定到指定的地址！！！";
        close(serverSocketFD);
        exit(1);
    }
    
    ret = listen(serverSocketFD, MAX_Q_LEN);
    if (ret < 0) {
        perror("无法开启监听！！！\n");
        self.messageLabel.stringValue = @"无法开启监听！！！";
        close(serverSocketFD);
        exit(1);
    }
    
    bool serverIsRunning = true;
    while (serverIsRunning) {
        struct sockaddr_in clientAddr;
        socklen_t clientAddrLen = sizeof clientAddr;
        
        
        int clientSocketFD = accept(serverSocketFD, (struct sockaddr *)&clientAddr, &clientAddrLen);
        
        bool clientConnected = true;
        if (clientSocketFD < 0) {
            perror("接受客户端连接时发生错误！！！\n");
            self.messageLabel.stringValue = @"接受客户端连接时发生错误！！！！";
            clientConnected = false;
        }
        
    }

    return YES;
    
    
}

-(void) getTagID {
    //Reset previous card number
    self.orgTextField.stringValue = @"";
    self.shortTextField.stringValue = @"";
    self.cardTagTextField.stringValue = @"";
    self.puTextField.stringValue = @"";
    
    int serverSocketFD = socket(AF_INET,SOCK_STREAM,0);
    if (serverSocketFD < 0) {
        perror("Could not create sokcet !!!\n");
        exit(1);
    }
    struct sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(SERVER_PORT);
    serverAddr.sin_addr.s_addr = htons(INADDR_ANY);
    
    int ret = bind(serverSocketFD, (struct sockaddr *)&serverAddr, sizeof serverAddr);
    
    if (ret < 0) {
        perror("无法将套接字绑定到指定的地址！！！\n");
        close(serverSocketFD);
        exit(1);
    }
    
    ret = listen(serverSocketFD, MAX_Q_LEN);
    if (ret < 0) {
        perror("无法开启监听！！！\n");
        close(serverSocketFD);
        exit(1);
    }
    
    
    
    
    bool serverIsRunning = true;
    while (serverIsRunning) {
        struct sockaddr_in clientAddr;
        socklen_t clientAddrLen = sizeof clientAddr;
        
        
        int clientSocketFD = accept(serverSocketFD, (struct sockaddr *)&clientAddr, &clientAddrLen);
        
        bool clientConnected = true;
        if (clientSocketFD < 0) {
            perror("接收客户端连接时发生错误！！！\n");
            clientConnected = false;
        }
        
        
        while (clientConnected) {
            char buffer[MAX_MSG_LEN + 1];
            //char buffer[MAX_MSG_LEN];
            
            ssize_t bytesToRecv = recv(clientSocketFD, buffer, sizeof buffer -1, 0);
            
            
            if (bytesToRecv > 0) {
                buffer[bytesToRecv] = '\0';
                change_enter_to_tail_zero(buffer, (int)bytesToRecv);
                
                printf("%s\n",buffer);
                
                if (!strcmp(buffer, "bye\r\n")) {
                    serverIsRunning = false;
                    clientConnected = false;
                    
                }
                //新增转16进制，必须先转为string 然后再append
                //Get Original Card ID
                NSMutableString *orgStr = [[NSMutableString alloc]init];
                for (int i = 0; i<sizeof(buffer)-1; i++) //如果buffer 不 －1， 会读取卡号多两位00
                {
                    [orgStr appendFormat:@"%02x",(unsigned char)buffer[i]];//如果不用unsigned char 会造成出现“ffffff”
                }
                NSLog(@"Original Card ID is: %@",orgStr);
                self.orgTextField.stringValue = orgStr;
                
                
                //choose Algorithm
                switch ([self.selectAlgo indexOfSelectedItem]) {
                    case 0:
                        NSLog(@"Card Algorithm is To18");
                        break;
                    case 1:  //02 - To3And5
                        NSLog(@"Card Algorithm is To3and5");
                    {
                        NSMutableString *str35_3 = [[NSMutableString alloc]init];
                        [str35_3 appendFormat:@"%03d",(unsigned char)buffer[5]];
                        
                        NSMutableString *str35_5 = [[NSMutableString alloc]init];
                        for (int i = 6; i<8; i++) {
                            [str35_5 appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int outputStr;
                        NSScanner *scanner = [NSScanner scannerWithString:str35_5];
                        [scanner scanHexInt:&outputStr];
                        NSLog(@"3+5 format Card ID is: %@,%d",str35_3,outputStr);
                        
                        NSString *display = [NSString stringWithFormat:@"%@,",str35_3];
                        NSString *tail =[NSString stringWithFormat:@"%d",outputStr];
                        self.cardTagTextField.stringValue = [display stringByAppendingString:tail];
                    }
                        break;
                    case 2:
                        NSLog(@"Card Algorithm is toCutBinR1to3And5");
                        break;
                    case 3:
                        NSLog(@"Card Algorithm is ToHex");
                        break;
                    case 4:
                        NSLog(@"Card Algorithm is toHex8");

                        break;
                    case 5:
                        NSLog(@"Card Algorithm is toHexKeepZero");

                        break;
                    case 6:
                        NSLog(@"Card Algorithm is ");

                        break;
                    case 7:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 8:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 9:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 10:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 11:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 12:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 13:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 14:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 15:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 16:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 17:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 18:
                        NSLog(@"Card Algorithm is ");
                        break;
                    case 19:
                        NSLog(@"Card Algorithm is ");
                        break;
                    default:
                        NSLog(@"Didn't choose any Algorithm!!");
                        break;
                       
                }
                
                //01 - To18
                
                
                
                
                
                //Get short Card ID
                 NSMutableString *shortStr = [[NSMutableString alloc]init];
                //01 Card Type = "ID"
                if (self.cardType.state == 0 ) {
                    NSLog(@"选中了ID");
                    for (int i = 5 ; i<sizeof(buffer)-3; i++) {
                        [shortStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                    }
                }
                //02 Card Type = "IC"
                else {
                for (int i = 3 ; i<sizeof(buffer)-4; i++) {
                    [shortStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                    }
                }
                
                
                NSLog(@"Short card ID is: %@",shortStr);
                self.shortTextField.stringValue = shortStr;
                
                
                
                
                /*
                NSMutableString *str35_3 = [[NSMutableString alloc]init];
                [str35_3 appendFormat:@"%03d",(unsigned char)buffer[5]];
                
                NSMutableString *str35_5 = [[NSMutableString alloc]init];
                for (int i = 6; i<8; i++) {
                    [str35_5 appendFormat:@"%02x",(unsigned char)buffer[i]];
                }
                unsigned int outputStr;
                NSScanner *scanner = [NSScanner scannerWithString:str35_5];
                [scanner scanHexInt:&outputStr];
                NSLog(@"3+5 format Card ID is: %@,%d",str35_3,outputStr);
                
                NSString *display = [NSString stringWithFormat:@"%@,",str35_3];
                NSString *tail =[NSString stringWithFormat:@"%d",outputStr];
                self.cardTagTextField.stringValue = [display stringByAppendingString:tail];
                */
                
                
                
                //Get PU Card ID
                NSMutableString *puStr = [[NSMutableString alloc]init];
                for (int i = 5 ; i<sizeof(buffer)-3; i++) {
                    [puStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                }
                NSLog(@"PrintUsage Card ID(Hex) is: %@",puStr);
                unsigned int puOutput;
                NSScanner *pUscanner = [NSScanner scannerWithString:puStr];
                [pUscanner scanHexInt:&puOutput];
                NSLog(@"PrintUsage Card ID(Dex) is: %d",puOutput);
                self.puTextField.stringValue = [NSString stringWithFormat:@"%d",puOutput];
                
                //only print message
                printf("Received!\n");
                
                
                size_t bytesToSend = send(clientSocketFD, buffer, bytesToRecv, 0);
                if (bytesToSend > 0) {
                    printf("Echo message has been send.\n");
                }
                
                
            }
            
            else {
                printf("client socket closed!\n");
                clientConnected = false;
            }
        }
        
        
        close(clientSocketFD);
    }
    
    close(serverSocketFD);
    
}



- (IBAction)getTag:(id)sender {
    //Show Alert message
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = @"Card Reader Connected!";
    alert.informativeText = @"Press OK and swipe card now.";
    [alert addButtonWithTitle:@"ok"];
    //[alert addButtonWithTitle:@"Second button"];
    [alert runModal];
    
    
    
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        [self getTagID];
    });
    self.getTagButton.title = @"Receiveing……";
    self.getTagButton.enabled = NO;
    
}

- (IBAction)connect:(id)sender {
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
    
    [self connection:@"119.119.115.8" port:SERVER_PORT];
    });
    
    self.messageLabel.stringValue = @"Conneted! ";
    self.testButton.enabled = NO;
    
    
    int serverSocketFD = socket(AF_INET,SOCK_STREAM,0);
    if (serverSocketFD < 0) {
        perror("Could not create sokcet !!!\n");
        exit(1);
    }
    struct sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(SERVER_PORT);
    serverAddr.sin_addr.s_addr = htons(INADDR_ANY);
    
    int ret = bind(serverSocketFD, (struct sockaddr *)&serverAddr, sizeof serverAddr);
    
    if (ret < 0) {
        perror("无法将套接字绑定到指定的地址！！！\n");
        close(serverSocketFD);
        exit(1);
    }
    
    ret = listen(serverSocketFD, MAX_Q_LEN);
    if (ret < 0) {
        perror("无法开启监听！！！\n");
        close(serverSocketFD);
        exit(1);
    }
    
    
    
    
    
    
    
    
    
}

- (IBAction)changeCardType:(NSButton *)sender {
    NSLog(@"%@",[sender title]);
}

- (IBAction)choosealgo:(id)sender {
   // NSLog(@"%@",[self.selectAlgo stringValue]);
    switch ([self.selectAlgo indexOfSelectedItem]) {
        case 0:
            NSLog(@"Card Algorithm is To18");
            self.messageLabel.stringValue = @"将原始卡号，转成16进制，分成1+3段，然后前1字节转为10进制，后3字节转为10进制，再与原始卡号拼为18位的卡号，不够补零。";
            break;
        case 1:
            NSLog(@"Card Algorithm is To3and5");
            self.messageLabel.stringValue = @"将原始卡号，取最低位3字节，再转换成3+5格式。\n如：原始数据 123456789，\n16进制为 07 5B CD 15，\n取最低位3字节 5B CD 15，\n再转成10进制091,52501。";
            break;
        case 2:
            NSLog(@"Card Algorithm is toCutBinR1to3And5");
            self.messageLabel.stringValue = @"将原始数据按照二进制，去掉最右一位，然后做成3+5.即再取第1字节和第2,3字节做成数字。保留前段的0。";
            break;
        case 3:
            NSLog(@"Card Algorithm is ToHex");
            self.messageLabel.stringValue = @"转换成16进制";
            break;
        case 4:
            NSLog(@"Card Algorithm is toHex8");
            self.messageLabel.stringValue = @"转换成16进制(共八位)";
            break;
        case 5:
            NSLog(@"Card Algorithm is toHexKeepZero");
            self.messageLabel.stringValue = @"转换成16进制,保留第一位0.";
            break;
        case 6:
            NSLog(@"Card Algorithm is toInt32");
            self.messageLabel.stringValue = @"转换成双字节的十进制，即Int32。";
            break;
        case 7:
            NSLog(@"Card Algorithm is toKeepOriginal");
            self.messageLabel.stringValue = @"保留原样。";
            break;
        case 8:
            NSLog(@"Card Algorithm is toLast2Bytes");
            self.messageLabel.stringValue = @"取最低位2字节，再转换成10进制。如：原始数据 123456789，16进制为 07 5B CD 15，取最低位2字节 CD 15，再转成10进制 52501。";
            break;
        case 9:
            NSLog(@"Card Algorithm is toLast2BytesHex");
            self.messageLabel.stringValue = @"取最低位2字节，再转换成16进制,不保留0。如：原始数据 123456789，16进制为 07 5B CD 15，取最低位2字节 CD15 ";
            break;
        case 10:
            NSLog(@"Card Algorithm is toLast2BytesHexKeepZero");
            self.messageLabel.stringValue = @"取最低位2字节，再转换成16进制。如：原始数据 123456789，16进制为 07 5B CD 15，取最低位2字节 CD15";
            break;
        case 11:
            NSLog(@"Card Algorithm is toLast3Bytes");
            self.messageLabel.stringValue = @"取最低位3字节，再转换成10进制。";
            break;
        case 12:
            NSLog(@"Card Algorithm is toLast3BytesHex");
            self.messageLabel.stringValue = @"取最低位3字节，再转换成16进制，不保留0。";
            break;
        case 13:
            NSLog(@"Card Algorithm is toLast3BytesHexKeepZero");
            self.messageLabel.stringValue = @"转换成16进制，取最低位3字节，不足则补0。\n如：原始数据 269208853，\n16进制为 10 0B CD 15，\n取最低位3字节 0B CD 15 ";
            break;
        case 14:
            NSLog(@"Card Algorithm is toLast3ByteskeepZero");
            self.messageLabel.stringValue = @"取最低位3字节，再转换成10进制,不足10位将用0填充。\n如：原始数据 123456789，\n16进制为 07 5B CD 15，\n取最低位3字节 5B CD 15，\n再转成10进制 0006016277。";
            break;
        case 15:
            NSLog(@"Card Algorithm is toLast4Bytes");
            self.messageLabel.stringValue = @"取后4字节，然后转成10进制。";
            break;
        case 16:
            NSLog(@"Card Algorithm is toLast6Bits");
            self.messageLabel.stringValue = @"将原始卡号，取后6位数字。\n如：原始数据 123456789，\n取后6位数字 456789。 ";
            break;
        case 17:
            NSLog(@"Card Algorithm is toPadLeftLength10");
            self.messageLabel.stringValue = @"取10位10进制数，不足10位前面补0，超过10位，取后10位。";
            break;
        case 18:
            NSLog(@"Card Algorithm is toReverse");
            self.messageLabel.stringValue = @"反转之后，10进制输出。\n如：原始数据 123456789，\n16进制为 07 5B CD 15-->15 CD 5B 07，\n再10进制输出 365779719 ";
            break;
        case 19:
            NSLog(@"Card Algorithm is toReverseHex");
            self.messageLabel.stringValue = @"反转之后，16进制输出。";
            break;
        default:
            NSLog(@"Didn't choose any Algorithm!!");
            self.messageLabel.stringValue = @"Didn't choose any Algorithm!!";
            break;
    }
    
    
}

@end
