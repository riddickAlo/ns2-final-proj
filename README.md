# ns2-final-proj
111-1 Final-term project for Computer Network course

## Scenario
Based on the practice resources, visit [lbs0912/Network-Simulator-NS2-Notes](https://github.com/lbs0912/Network-Simulator-NS2-Notes)    
  
We assume there are 4 nodes in a network. Node 0 starts a FTP transmission through TCP to node 3.  
In the view of node 0, the link with node 1 looks good(10Mb & 1ms). It can't acknowledge that there would be a bottleneck between node 1 and node 2. And node 3 can't either.  
  
This would set a scenario which close to reality. Help us to observe why NewReno outperforms Reno.

![image](https://github.com/riddickAlo/ns2-final-proj/blob/main/images/System%20distruibution.PNG)

## Results
If the congestion window is larger than 12.44 packets as shown below, it will cause packet loss.  
New Reno adds a slight modification over Reno for handling multiple packets loss. It intriduced Fast-Recovery
  
![image](https://github.com/riddickAlo/ns2-final-proj/blob/main/images/Result.PNG)

## Dependancies
- ubuntu 18.04
- NS2 2.3.5
- Gnuplot version 5.2
- Nam 1.15
- TCL 8.6.0


