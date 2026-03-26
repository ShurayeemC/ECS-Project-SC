### VPC

Created a custom VPC with 4 subnets - 2 private and 2 public and placed a public and a private in 2 different AZs for high availability 

Created 2 NAT gateways and placed both inside each public subnet 

Created an IGW so traffic can be routed 

Created 2 route tables - associated both private subnets in one route table and both public subnets in the other 

Created the NAT gateway routes for the private subnet route table and configured it so that the gateways are routed to each subnet 

Created the IGW route for the public subnet route table  

### ECS

Created the ECS cluster and configured all necessary options 

Created the task definition - encountered a problem and solved it - the problem was to map the HTTP protocol to port 3000 because that is where the application is hosted 

 

### ALB

Created the ALB and target groups -  security group  allowed traffic on port 80 

The security group for my tasks allowed inbound traffic from the ALBs security group and Custom TCP port 3000 

Target group was hosted on port 3000 as this was where my application was hosted 

The target group is the private IPv4 addresses which are assigned to my tasks from ECS cluster 

 

### Route 53

I registered the domain - [nginxunais.com](http://nginxunais.com) then also created a subdomain in the public hosted zone called tm.nginxunais.com

Once I had done I made sure that the value assigned to the domain was the albs domain name so that whenever someone types in my domain in the browser, the traffic is routed to the ALB

### ACM

I requested a TSL certificate for my sub domain so that traffic from HTTPS protocol is able to reach to my website which ensures that data is secure 

I allowed inbound traffic on my ALB security group from port 443 and I also created a HTTPS listener which I then had to specify the cert on my ALB which allowed for the data to be decrypted once the traffic reached my ALB so that the data was readable for users and they connect to the site securely 

### Redirection

On the HTTP listener for the ALB, edit listener and choose redirect to URL and then specify the HTTPS protocol on port 443
