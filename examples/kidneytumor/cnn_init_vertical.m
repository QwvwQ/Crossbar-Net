function net = cnn_init_vertical(varargin)
% CNN_MNIST_LENET Initialize a CNN similar for MNIST
opts.batchNormalization = true ;
opts.networkType = 'simplenn' ;
opts.epochsnum='V1';
[opts, varargin]= vl_argparse(opts, varargin) ;

rng('default');
rng(0) ;

f=1/100 ;
net.layers = {} ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(5,3,1,16, 'single'), zeros(1, 16, 'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(5,3,16,36, 'single'), zeros(1, 36, 'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'max', ...
                           'pool', [2 2], ...
                           'stride', 2, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(5,3,36,64, 'single'),zeros(1,64,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'max', ...
                           'pool', [2 2], ...
                           'stride', 2, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(5,3,64,64, 'single'),  zeros(1,64,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(6,1,64,64, 'single'),  zeros(1,64,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(6,1,64,64, 'single'),  zeros(1,64,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(7,1,64,500, 'single'),  zeros(1,500,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(1,1,500,2, 'single'), zeros(1,2,'single')}}, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'softmaxloss') ;

% optionally switch to batch normalization
if opts.batchNormalization
  net = insertBnorm(net, 1) ;
  net = insertBnorm(net, 4) ;
  net = insertBnorm(net, 7) ;
end

% Meta parameters
net.meta.inputSize = [100 20 1] ;
net.meta.trainOpts.learningRate = 0.001 ;
net.meta.trainOpts.batchSize = 100 ;
if strcmp(opts.epochsnum,'V1')
    net.meta.trainOpts.numEpochs = 30 ;
end
if strcmp(opts.epochsnum,'V2')
    net.meta.trainOpts.numEpochs = 50 ;
end
if strcmp(opts.epochsnum,'V3')
    net.meta.trainOpts.numEpochs = 70 ;
end

% Fill in defaul values
net = vl_simplenn_tidy(net) ;

% Switch to DagNN if requested
switch lower(opts.networkType)
  case 'simplenn'
    % done
  case 'dagnn'
    net = dagnn.DagNN.fromSimpleNN(net, 'canonicalNames', true) ;
    net.addLayer('top1err', dagnn.Loss('loss', 'classerror'), ...
      {'prediction', 'label'}, 'error') ;
    net.addLayer('top5err', dagnn.Loss('loss', 'topkerror', ...
      'opts', {'topk', 5}), {'prediction', 'label'}, 'top5err') ;
  otherwise
    assert(false) ;
end

% --------------------------------------------------------------------
function net = insertBnorm(net, l)
% --------------------------------------------------------------------
assert(isfield(net.layers{l}, 'weights'));
ndim = size(net.layers{l}.weights{1}, 4);
layer = struct('type', 'bnorm', ...
               'weights', {{ones(ndim, 1, 'single'), zeros(ndim, 1, 'single')}}, ...
               'learningRate', [1 1 0.005], ...
               'weightDecay', [0 0]) ;
net.layers{l}.biases = [] ;
net.layers = horzcat(net.layers(1:l), layer, net.layers(l+1:end)) ;