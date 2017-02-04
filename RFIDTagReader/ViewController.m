//
//  ViewController.m
//  RFIDTagReader
//
//  Created by vingleo on 16/7/15.
//  Copyright © 2016年 Vingleo. All rights reserved.
//  Updated 20160815 by vingleo
//  Fix some card get card number display negative number

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#import "ViewController.h"

//static const short SERVER_PORT = 8600;
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

- (NSString *)binaryStringWithInteger:(NSInteger)value{
    NSMutableString *string = [NSMutableString string];  while (value)
    {
        [string insertString:(value & 1)? @"1": @"0" atIndex:0];
        value /= 2;  }
    return string;
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
    int SERVER_PORT = [self.portTextField intValue];
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
                    [orgStr appendFormat:@"%02x ",(unsigned char)buffer[i]];//如果不用unsigned char 会造成出现“ffffff”
                }
                NSLog(@"Original Card ID is: %@",orgStr);
                self.orgTextField.stringValue = orgStr;
                
                
                //choose Algorithm
                switch ([self.selectAlgo indexOfSelectedItem]) {
                    case 0:  //01 - To18
                        NSLog(@"Card Algorithm is To18");
                    {
                        NSString *toPart1Output,*toPart2Output,*toPart3Output;
                        NSMutableString *part1 = [[NSMutableString alloc]init];
                        for (int i = 4; i<sizeof(buffer)-6; i++) {
                            [part1 appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        
                        if ([part1 length]==8) {
                            unsigned long toPart1Int;
                            toPart1Int = strtoul([[part1 substringWithRange:NSMakeRange(0, 8)]UTF8String], 0, 16);
                            toPart1Output = [NSString stringWithFormat:@"%ld",toPart1Int];
                        }
                        else {
                            unsigned int toPart1Int;
                            NSScanner *part1scanner = [NSScanner scannerWithString:part1];
                            [part1scanner scanHexInt:&toPart1Int];
                            toPart1Output = [NSString stringWithFormat:@"%d",toPart1Int];
                        }
                        //NSLog(@"part 1 is %d",part1outputStr);
                        NSMutableString *part2 = [[NSMutableString alloc]init];
                        for (int i = 5; i<sizeof(buffer)-4; i++) {
                            [part2 appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        if ([part2 length]==8) {
                            unsigned long toPart2Int;
                            toPart2Int = strtoul([[part2 substringWithRange:NSMakeRange(0, 8)]UTF8String], 0, 16);
                            toPart2Output = [NSString stringWithFormat:@"%ld",toPart2Int];
                        }
                        else {
                            unsigned int toPart2Int;
                            NSScanner *part2scanner = [NSScanner scannerWithString:part2];
                            [part2scanner scanHexInt:&toPart2Int];
                            toPart2Output = [NSString stringWithFormat:@"%d",toPart2Int];
                            
                        }
                         //NSLog(@"part 2 is %d",part2outputStr);
                        
                        NSMutableString *part3 = [[NSMutableString alloc]init];
                        for (int i = 3; i<sizeof(buffer)-4; i++) {
                            [part3 appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        if ([part3 length]==8) {
                            unsigned long toPart3Int;
                            toPart3Int = strtoul([[part3 substringWithRange:NSMakeRange(0, 8)]UTF8String], 0, 16);
                            toPart3Output = [NSString stringWithFormat:@"%ld",toPart3Int];
                        }
                        else {
                            unsigned int toPart3Int;
                            NSScanner *part3scanner = [NSScanner scannerWithString:part3];
                            [part3scanner scanHexInt:&toPart3Int];
                            toPart3Output = [NSString stringWithFormat:@"%d",toPart3Int];

                        }
                        
                        //NSLog(@"part 3 is %d",part3outputStr);
                        NSString *to18Str = [NSString stringWithFormat:@"%@%@%@",toPart3Output,toPart1Output,toPart2Output];
                        self.cardTagTextField.stringValue = to18Str;
                     }
                        break;
                    case 1:  //02 - To3And5
                        NSLog(@"Card Algorithm is To3and5");
                    {
                        //----01 Card Type = "IC"
                        if (self.cardType.state == 1 ) {
                        NSMutableString *part1 = [[NSMutableString alloc]init];
                        for (int i = 4; i<sizeof(buffer)-6; i++) {
                            [part1 appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int part1outputStr;
                        NSScanner *part1scanner = [NSScanner scannerWithString:part1];
                        [part1scanner scanHexInt:&part1outputStr];
                        //NSLog(@"part 1 is %d",part1outputStr);
                        
                        NSMutableString *part2 = [[NSMutableString alloc]init];
                        for (int i = 5; i<sizeof(buffer)-4; i++) {
                            [part2 appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int part2outputStr;
                        NSScanner *part2scanner = [NSScanner scannerWithString:part2];
                        [part2scanner scanHexInt:&part2outputStr];
                        //NSLog(@"part 2 is %d",part2outputStr);
                        
                        NSString *to3And5 = [NSString stringWithFormat:@"%d%d",part1outputStr,part2outputStr];
                        self.cardTagTextField.stringValue = to3And5;
                        }
                        //----02 Card Type = "ID"
                        else {
                            NSMutableString *part1 = [[NSMutableString alloc]init];
                            for (int i = 5; i<sizeof(buffer)-5; i++) {
                                [part1 appendFormat:@"%02x",(unsigned char)buffer[i]];
                            }
                            NSMutableString *part2 = [[NSMutableString alloc]init];
                            for (int i = 6; i<sizeof(buffer)-3; i++) {
                                [part2 appendFormat:@"%02x",(unsigned char)buffer[i]];
                            }
                            unsigned int part1outputStr;
                            NSScanner *part1scanner = [NSScanner scannerWithString:part1];
                            [part1scanner scanHexInt:&part1outputStr];
                            //NSLog(@"part1 is %d",part1outputStr);
                            unsigned int part2outputStr;
                            NSScanner *part2scanner = [NSScanner scannerWithString:part2];
                            [part2scanner scanHexInt:&part2outputStr];
                            //NSLog(@"part2 is %d",part2outputStr);
                            
                            self.cardTagTextField.stringValue = [NSString stringWithFormat:@"%03d%05d",part1outputStr,part2outputStr];
                       }
                    }
                        break;
                    case 2: //03 - toCutBinR1to3And5
                        NSLog(@"Card Algorithm is toCutBinR1to3And5");
                    {
                        NSMutableString *before = [[NSMutableString alloc]init];
                        for (int i = 4; i<sizeof(buffer)-4; i++) {
                            [before appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        
                        unsigned int beforeOutputStr;
                        NSScanner *beforeScanner = [NSScanner scannerWithString:before];
                        [beforeScanner scanHexInt:&beforeOutputStr];
                        NSString  *afterIntStr = [NSString stringWithFormat:@"%d",beforeOutputStr];
                        NSLog(@"after int is %@",afterIntStr);
                        
                        unsigned int afterBin = beforeOutputStr / 2; //右移一位 >>1 等于 /2
                        
                        //以下代码块为十进制int 转二进制 int,此处不需要
                        /*unsigned int i;
                        int n=sizeof(int)*CHAR_BIT;
                        int mask = 1<<(n-1);
                        for (i=1; i<=n; i++) {
                            //putchar(((beforeOutputStr&mask)==0)?'0':'1');
                            putchar(((afterBin&mask)==0)?'0':'1');
                            //beforeOutputStr<<=1;
                            afterBin<<=1;
                        }
                        NSLog(@"%d",afterBin);
                         */
                        NSLog(@"CutBinR1to3And5 Hex is : %x",afterBin);
                        NSString *cutBinR1to3And5Str = [NSString stringWithFormat:@"%x",afterBin];
                        NSString *part1 = [cutBinR1to3And5Str substringToIndex:2];
                        NSLog(@"part1(hex)is %@",part1);
                        unsigned int part1outputStr;
                        NSScanner *part1scanner = [NSScanner scannerWithString:part1];
                        [part1scanner scanHexInt:&part1outputStr];
                        NSLog(@"part1(Dec) is %d",part1outputStr);
                        NSString *part2 = [cutBinR1to3And5Str substringFromIndex:2];
                        NSLog(@"part2(hex)is %@",part2);
                        unsigned int part2outputStr;
                        NSScanner *part2scanner = [NSScanner scannerWithString:part2];
                        [part2scanner scanHexInt:&part2outputStr];
                        NSLog(@"part2(Dec) is %d",part2outputStr);
                        NSLog(@"cutBinR1to3And5 is %d%d",part1outputStr,part2outputStr);
                        NSString *toCutBinR1to3And5Str = [NSString stringWithFormat:@"%03d%05d",part1outputStr,part2outputStr];
                        self.cardTagTextField.stringValue = toCutBinR1to3And5Str;
                    }
                        break;
                    case 3: //04 - ToHex
                        NSLog(@"Card Algorithm is ToHex");
                    {
                        NSMutableString *toHexStr = [[NSMutableString alloc]init];
                        for (int i = 3 ; i<sizeof(buffer)-4; i++) {
                            [toHexStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                            }
                        NSLog(@"ToHex card ID is: %@",toHexStr);
                        if ([toHexStr hasPrefix:@"0"]) {
                            [toHexStr deleteCharactersInRange:NSMakeRange(0,1)];
                        }
                        
                        self.cardTagTextField.stringValue = toHexStr;
                    }
                        break;
                    case 4: //05 - toHex8
                        NSLog(@"Card Algorithm is toHex8");
                    {
                        NSMutableString *toHex8Str = [[NSMutableString alloc]init];
                        for (int i = 3 ; i<sizeof(buffer)-4; i++) {
                            [toHex8Str appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        NSLog(@"ToHex card ID is: %@",toHex8Str);
                        self.cardTagTextField.stringValue = toHex8Str;
                    }
                        break;
                    case 5: //06 - toHexKeepZero
                        NSLog(@"Card Algorithm is toHexKeepZero");
                    {
                        NSMutableString *toHexKeepZeroStr = [[NSMutableString alloc]init];
                        for (int i = 3 ; i<sizeof(buffer)-4; i++) {
                            [toHexKeepZeroStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        NSLog(@"toHexKeepZero card ID is: %@",toHexKeepZeroStr);
                        self.cardTagTextField.stringValue = toHexKeepZeroStr;
                    }
                        break;
                    case 6: //07 - toInt32
                        NSLog(@"Card Algorithm is toInt32");
                    {
                        NSMutableString *toInt32Str = [[NSMutableString alloc]init];
                        for (int i = 3; i<sizeof(buffer)-4; i++) {
                            [toInt32Str appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        
                        if ([toInt32Str length]==8)
                        {
                            unsigned long toInt32Int;  //注意此处需要用长整型保存数值
                            toInt32Int = strtoul([[toInt32Str substringWithRange:NSMakeRange(0, 8)]UTF8String], 0, 16);
                            
                            NSString *toInt32Output = [NSString stringWithFormat:@"%ld",toInt32Int];
                            self.cardTagTextField.stringValue = toInt32Output;
                        }
                        else {
                            unsigned int toInt32;
                            NSScanner *toInt32scanner = [NSScanner scannerWithString:toInt32Str];
                            [toInt32scanner scanHexInt:&toInt32];
                            //NSLog(@"toInt32scanner  is %d",toInt32);
                            
                            NSString *toInt32StrOutput = [NSString stringWithFormat:@"%d",toInt32];
                            self.cardTagTextField.stringValue = toInt32StrOutput;
                        }
                    }
                        break;
                    case 7:  //08 - toKeepOriginal
                        NSLog(@"Card Algorithm is toKeepOriginal");
                    {
                        NSMutableString *toKeepOriginalStr = [[NSMutableString alloc]init];
                        for (int i = 3; i<sizeof(buffer)-4; i++) {
                            [toKeepOriginalStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        
                         if ([toKeepOriginalStr length]==8)
                         {
                             unsigned long toKeepOriginalInt;  //注意此处需要用长整型保存数值
                             toKeepOriginalInt = strtoul([[toKeepOriginalStr substringWithRange:NSMakeRange(0, 8)]UTF8String], 0, 16);
                             
                             NSString *toKeepOriginalOutput = [NSString stringWithFormat:@"%ld",toKeepOriginalInt];
                             self.cardTagTextField.stringValue = toKeepOriginalOutput;
                         }
                         else
                         {
                             unsigned int toKeepOriginal;
                             NSScanner *toKeepOriginalScanner = [NSScanner scannerWithString:toKeepOriginalStr];
                             [toKeepOriginalScanner scanHexInt:&toKeepOriginal];
                             NSString *toKeepOriginalOutput = [NSString stringWithFormat:@"%d",toKeepOriginal];
                             self.cardTagTextField.stringValue = toKeepOriginalOutput;
                         }
                        
                        
                        
                    }
                        break;
                    case 8:  //09 - toLast2Bytes
                        NSLog(@"Card Algorithm is toLast2Bytes");
                    {
                        NSMutableString *toLast2BytesStr = [[NSMutableString alloc]init];
                        for (int i = 5; i<sizeof(buffer)-4; i++) {
                            [toLast2BytesStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int toLast2BytesInt;
                        NSScanner *toLast2BytesScanner = [NSScanner scannerWithString:toLast2BytesStr];
                        [toLast2BytesScanner scanHexInt:&toLast2BytesInt];
                        //NSLog(@"part 1 is %d",part1outputStr);
                        NSString *toLast2BytesStrOutput = [NSString stringWithFormat:@"%d",toLast2BytesInt];
                        self.cardTagTextField.stringValue = toLast2BytesStrOutput;
                    }
                        break;
                    case 9:  //10 - toLast2BytesHex
                        NSLog(@"Card Algorithm is toLast2BytesHex");
                    {
                        NSMutableString *toLast2BytesHexStr = [[NSMutableString alloc]init];
                        for (int i = 5; i<sizeof(buffer)-4; i++) {
                            [toLast2BytesHexStr appendFormat:@"%x",(unsigned char)buffer[i]];
                        }
                        self.cardTagTextField.stringValue = toLast2BytesHexStr;

                    }
                        break;
                    case 10:  //11 - toLast2BytesHexKeepZero
                        NSLog(@"Card Algorithm is toLast2BytesHexKeepZero");
                    {
                        NSMutableString *toLast2BytesHexKeepZeroStr = [[NSMutableString alloc]init];
                        for (int i = 5; i<sizeof(buffer)-4; i++) {
                            [toLast2BytesHexKeepZeroStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        self.cardTagTextField.stringValue = toLast2BytesHexKeepZeroStr;
                    }
                        break;
                    case 11:  //12 - toLast3Bytes
                        NSLog(@"Card Algorithm is toLast3Bytes");
                    {
                        NSMutableString *toLast3BytesStr = [[NSMutableString alloc]init];
                        for (int i = 4; i<sizeof(buffer)-4; i++) {
                            [toLast3BytesStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int toLast3BytesStrInt;
                        NSScanner *toLast3BytesStrScanner = [NSScanner scannerWithString:toLast3BytesStr];
                        [toLast3BytesStrScanner scanHexInt:&toLast3BytesStrInt];
                        //NSLog(@"part 1 is %d",part1outputStr);
                        NSString *toLast3BytesOutput = [NSString stringWithFormat:@"%d",toLast3BytesStrInt];
                        self.cardTagTextField.stringValue = toLast3BytesOutput;
                    }
                        break;
                    case 12:  //13 - toLast3BytesHex
                        NSLog(@"Card Algorithm is toLast3BytesHex");
                    {
                        NSMutableString *toLast3BytesHexStr = [[NSMutableString alloc]init];
                        for (int i = 4; i<sizeof(buffer)-4; i++) {
                            [toLast3BytesHexStr appendFormat:@"%x",(unsigned char)buffer[i]];
                        }
                        self.cardTagTextField.stringValue = toLast3BytesHexStr;
                    }
                        break;
                    case 13:  //14 - toLast3BytesHexKeepZero
                        NSLog(@"Card Algorithm is toLast3BytesHexKeepZero");
                    {
                        NSMutableString *toLast3BytesHexKeepZeroStr = [[NSMutableString alloc]init];
                        for (int i = 4; i<sizeof(buffer)-4; i++) {
                            [toLast3BytesHexKeepZeroStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        self.cardTagTextField.stringValue = toLast3BytesHexKeepZeroStr;
                    }
                        break;
                    case 14:  //15 - toLast3ByteskeepZero
                        NSLog(@"Card Algorithm is toLast3ByteskeepZero");
                    {
                        NSMutableString *toLast3ByteskeepZeroStr = [[NSMutableString alloc]init];
                        for (int i = 4; i<sizeof(buffer)-4; i++) {
                            [toLast3ByteskeepZeroStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int toLast3ByteskeepZeroInt;
                        NSScanner *toLast3ByteskeepZeroScanner = [NSScanner scannerWithString:toLast3ByteskeepZeroStr];
                        [toLast3ByteskeepZeroScanner scanHexInt:&toLast3ByteskeepZeroInt];
                        NSString *toLast3ByteskeepZeroOutput = [NSString stringWithFormat:@"%010d",toLast3ByteskeepZeroInt];
                        self.cardTagTextField.stringValue = toLast3ByteskeepZeroOutput;
                    }
                        break;
                    case 15:  //16 - toLast4Bytes
                        NSLog(@"Card Algorithm is toLast4Bytes");
                    {
                        NSMutableString *toLast4BytesStr = [[NSMutableString alloc]init];
                        for (int i = 3; i<sizeof(buffer)-4; i++) {
                            [toLast4BytesStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int toLast4BytesInt;
                        NSScanner *toLast4BytesScanner = [NSScanner scannerWithString:toLast4BytesStr];
                        [toLast4BytesScanner scanHexInt:&toLast4BytesInt];
                        NSString *toLast4BytesOutput = [NSString stringWithFormat:@"%d",toLast4BytesInt];
                        self.cardTagTextField.stringValue = toLast4BytesOutput;
                    }
                        break;
                    case 16:  //17 - toLast6Bits
                        NSLog(@"Card Algorithm is toLast6Bits");
                    {
                        NSMutableString *toLast6BitsStr = [[NSMutableString alloc]init];
                        for (int i = 3; i<sizeof(buffer)-4; i++) {
                            [toLast6BitsStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int toLast6BitsInt;
                        NSScanner *toLast6BitsScanner = [NSScanner scannerWithString:toLast6BitsStr];
                        [toLast6BitsScanner scanHexInt:&toLast6BitsInt];
                        NSString *toLast6BitsIntOutput = [[NSString stringWithFormat:@"%010d",toLast6BitsInt] substringFromIndex:4];
                        self.cardTagTextField.stringValue = toLast6BitsIntOutput;
                    }
                        break;
                    case 17:  //18 - toPadLeftLength10
                        NSLog(@"Card Algorithm is toPadLeftLength10");
                    {
                        NSMutableString *toPadLeftLength10Str = [[NSMutableString alloc]init];
                        for (int i = 3; i<sizeof(buffer)-4; i++) {
                            [toPadLeftLength10Str appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        unsigned int toPadLeftLength10Int;
                        NSScanner *toPadLeftLength10Scanner = [NSScanner scannerWithString:toPadLeftLength10Str];
                        [toPadLeftLength10Scanner scanHexInt:&toPadLeftLength10Int];
                        NSString *toPadLeftLength10Output = [NSString stringWithFormat:@"%010d",toPadLeftLength10Int];
                        self.cardTagTextField.stringValue = toPadLeftLength10Output;
                    }
                        break;
                    case 18:  //19 - toReverse
                        NSLog(@"Card Algorithm is toReverse");
                    {
                        NSMutableString *toReverseStr = [[NSMutableString alloc]init];
                        //NSLog(@"toReverseStr is %@",toReverseStr);
                        for (int i = sizeof(buffer)-5; i>2; i--) {
                            [toReverseStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        if ([toReverseStr length]==8) {
                            unsigned long toReverseInt;  //使用长整型
                            toReverseInt = strtoul([[toReverseStr substringWithRange:NSMakeRange(0, 8)]UTF8String], 0, 16);
                            NSString *toReverseOutput = [NSString stringWithFormat:@"%ld",toReverseInt];
                            self.cardTagTextField.stringValue = toReverseOutput;
                        }
                        else {
                            unsigned int toReverseInt;
                            NSScanner *toReverseScanner = [NSScanner scannerWithString:toReverseStr];
                            [toReverseScanner scanHexInt:&toReverseInt];
                            NSString *toReverseOutput = [NSString stringWithFormat:@"%010d",toReverseInt];
                            self.cardTagTextField.stringValue = toReverseOutput;
                        }
                        
                    }
                        break;
                    case 19: //20 - toReverseHex
                        NSLog(@"Card Algorithm is toReverseHex");
                    {
                        NSMutableString *toReverseHexStr = [[NSMutableString alloc]init];
                        for (int i = sizeof(buffer)-5; i>2; i--) {
                            [toReverseHexStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                        }
                        self.cardTagTextField.stringValue = toReverseHexStr;
                    }
                        break;
                    default:
                        NSLog(@"Didn't choose any Algorithm!!");
                        break;
                       
                }
                
                
                
                
                
                
                
                //Get short Card ID
                 NSMutableString *shortStr = [[NSMutableString alloc]init];
                //----01 Card Type = "ID"
                if (self.cardType.state == 0 ) {
                    NSLog(@"选中了ID");
                    for (int i = 5 ; i<sizeof(buffer)-3; i++) {
                        [shortStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                    }
                }
                //----02 Card Type = "IC"
                else {
                    NSLog(@"选中了IC");
                for (int i = 3 ; i<sizeof(buffer)-4; i++) {
                    [shortStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                    }
                }
                
                
                NSLog(@"Short card ID is: %@",shortStr);
                self.shortTextField.stringValue = [shortStr uppercaseString];
                
                
                
                
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
                //----01 Card Type = "ID"
                if (self.cardType.state == 0 ) {
                    NSLog(@"选中了ID");
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
                }
                //----02 Card Type = "IC"
                else {
                    NSLog(@"选中了IC");
                    NSMutableString *puStr = [[NSMutableString alloc]init];
                    for (int i = 3 ; i<sizeof(buffer)-4; i++) {
                        [puStr appendFormat:@"%02x",(unsigned char)buffer[i]];
                    }
                    NSLog(@"PrintUsage Card ID(Hex) is: %@",puStr);
                    
                    unsigned long puOutput;  //注意此处需要用长整型保存数值
                    if ([puStr length]==8) {
                        puOutput = strtoul([[puStr substringWithRange:NSMakeRange(0, 8)]UTF8String], 0, 16);
                        
                        NSString *toKeepOriginalOutput = [NSString stringWithFormat:@"%ld",puOutput];
                        self.puTextField.stringValue = toKeepOriginalOutput;
                    }
                    else {
                        unsigned int puOutput;
                        NSScanner *pUscanner = [NSScanner scannerWithString:puStr];
                        [pUscanner scanHexInt:&puOutput];
                        NSLog(@"PrintUsage Card ID(Dex) is: %d",puOutput);
                        self.puTextField.stringValue = [NSString stringWithFormat:@"%d",puOutput];

                    }
                }
                
                
                
                
                
                //以下是发送部分代码， 可删除
                /*
                size_t bytesToSend = send(clientSocketFD, buffer, bytesToRecv, 0);
                if (bytesToSend > 0) {
                    printf("Echo message has been send.\n");
                }
                */
                
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
    if ([self.portTextField.stringValue length]==0) {
        NSAlert *alert = [[NSAlert alloc]init];
        alert.messageText = @"Please enter port number.";
        alert.informativeText = @"Enter port number like \"8600\".";
        [alert addButtonWithTitle:@"ok"];
        [alert runModal];
    }
    
    else if ([self.selectAlgo indexOfSelectedItem]<0) {
        NSAlert *alert = [[NSAlert alloc]init];
        alert.messageText = @"Please choose a Algorithm.";
        alert.informativeText = @"Check the description for detail.";
        [alert addButtonWithTitle:@"ok"];
        [alert runModal];
    }
    else {
        NSAlert *alert = [[NSAlert alloc]init];
        alert.messageText = @"Card Reader Connected!";
        alert.informativeText = @"Press OK and swipe card now.";
        [alert addButtonWithTitle:@"ok"];
        [alert runModal];
        
        dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue, ^{
            
            [self getTagID];
        });
        self.getTagButton.title = @"Receiveing……";
        self.getTagButton.enabled = NO;
    }
}

- (IBAction)connect:(id)sender {
//    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
//    dispatch_async(queue, ^{
//    
//    [self connection:@"119.119.115.8" port:SERVER_PORT];
//    });
//    
//    self.messageLabel.stringValue = @"Conneted! ";
//    self.testButton.enabled = NO;
//    
//    
//    int serverSocketFD = socket(AF_INET,SOCK_STREAM,0);
//    if (serverSocketFD < 0) {
//        perror("Could not create sokcet !!!\n");
//        exit(1);
//    }
//    struct sockaddr_in serverAddr;
//    serverAddr.sin_family = AF_INET;
//    serverAddr.sin_port = htons(SERVER_PORT);
//    serverAddr.sin_addr.s_addr = htons(INADDR_ANY);
//    
//    int ret = bind(serverSocketFD, (struct sockaddr *)&serverAddr, sizeof serverAddr);
//    
//    if (ret < 0) {
//        perror("无法将套接字绑定到指定的地址！！！\n");
//        close(serverSocketFD);
//        exit(1);
//    }
//    
//    ret = listen(serverSocketFD, MAX_Q_LEN);
//    if (ret < 0) {
//        perror("无法开启监听！！！\n");
//        close(serverSocketFD);
//        exit(1);
//    }
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
