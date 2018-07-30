%% ls training on filtrate data
% least square to get the layer3 parameters
%% prepare training data
clear
clc
str = 'data2/';% with .4 .6 combination
load(strcat(str,'weights1.mat'));
load(strcat(str,'weights2.mat'));
load(strcat(str,'weights3.mat'));
load(strcat(str,'biases1.mat'));
load(strcat(str,'biases2.mat'));
load(strcat(str,'biases3.mat'));

str1 = 'filte_data/';
load(strcat(str1, 'new_testX.mat'));
load(strcat(str1, 'new_testY.mat'));
load(strcat(str1, 'new_trainX.mat'));
load(strcat(str1, 'new_trainY.mat'));

layer1 = max(0,new_trainX * double(weights1) + double(biases1));
layer2 = max(0,layer1 * double(weights2) + double(biases2));
encode = layer2;
num = size(encode, 1);
encode = [encode, ones(num,1)];
lambda=0.9998;
%% online ls
theta = zeros(41,9);
F = 10000*eye(41);
F_M = F;
for k = 1:8
    F_M = blkdiag(F_M, F);
end
j = 1;
E = ones(num,9);
% X_theta = zeros(41*9,41*9);
X_theta = rand(41*9,41*9);
W = .02^2; % for now
for i = 1:num
    for j = 1:9
        F = F_M(41*(j-1)+1:41*j, 41*(j-1)+1:41*j);
        phi = encode(i, :);
        k = F*phi'/(lambda+phi*F*phi');
        theta(:,j) =  theta(:,j) + k*(new_trainY(i,j) - phi*theta(:,j));
        F = (F - k*phi*F)/lambda;
        F_M(41*(j-1)+1:41*j, 41*(j-1)+1:41*j) = F;
        err = new_trainY(:,j) - encode*theta(:,j);
        E(i,j)=norm(err,2);
    end
    % calculate variance of states
    Phi = phi;
    for k = 1:8
        Phi = blkdiag(Phi, phi);
    end
    Xx = Phi*X_theta*Phi' + W;
    X_theta = F_M*Phi'*Xx*Phi*F_M - X_theta*Phi'*Phi*F_M - F_M*Phi'*Phi*X_theta + X_theta;
end

%% check the learning process
plot(1:num, E(:,4), '*-')       
for j = 1:9
    err_NN(j) = norm(double( new_trainY(:,j) - layer2*weights3(:,j) - biases3(j)),2);
end
%% test
layer1 = max(0,new_testX * double(weights1) + double(biases1));
layer2 = max(0,layer1 * double(weights2) + double(biases2));
encode = layer2;
num = size(encode,1);
encode = [encode, ones(num,1)];
E = []
tsigma = [];
error = 100*ones(num, 9);
count = 0;
for i = 1:num
    for j = 1:9
        F = F_M(41*(j-1)+1:41*j, 41*(j-1)+1:41*j);
        phi = encode(i, :);
        k = F*phi'/(lambda+phi*F*phi');
        theta(:,j) =  theta(:,j) + k*(new_testY(i,j) - phi*theta(:,j));
        F = (F - k*phi*F)/lambda;
        F_M(41*(j-1)+1:41*j, 41*(j-1)+1:41*j) = F;
        err = new_testY(i,j) - phi*theta(:,j);
%         sigma = sqrt(Xx(1,1));
        sigma = sqrt(Xx(j,j)); %we should make sure that each of the dimension matched to its corresponding standard deviation
        nn = size(find(err>3*sigma | err<-3*sigma),1);
        count = count + nn;
%         E(i,j)=norm(err,2);
        error(i, j) = new_testY(i,j) - phi*theta(:,j);
    end
    % calculate variance of states
    Phi = phi;
    for k = 1:8
        Phi = blkdiag(Phi, phi);
    end
    Xx = Phi*X_theta*Phi' + W;
    X_theta = F_M*Phi'*Xx*Phi*F_M - X_theta*Phi'*Phi*F_M - F_M*Phi'*Phi*X_theta + X_theta;
end
disp(1- count/num/9)
%% count the 3 sigma error
% % ignore this now
% R = [eye(3), zeros(3,3), zeros(3,3)];
% Var = R*Xx*R';
% plot the 3 sigma error 
figure
plot(1:num, error(:,1),1:num, error(:,2),1:num, error(:,3),1:num, error(:,4),...
    1:num, error(:,5),1:num, error(:,6),1:num, error(:,7),1:num, error(:,8),...
    1:num, error(:,9))

legend('x in k+1', 'y in k+1', 'z in k+1',...
    'x in k+2', 'y in k+2', 'z in k+2',...
    'x in k+3', 'y in k+3', 'z in k+3');
xlabel('index')
ylabel('error')
hold on
save
