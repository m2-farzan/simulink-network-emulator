function msfuntmpl_basic(Block)
    setup(Block);
function setup(Block)
    Block.NumInputPorts = 2;
    Block.NumOutputPorts = 2;
    Block.SetPreCompInpPortInfoToDynamic;
    Block.SetPreCompOutPortInfoToDynamic;
    Block.NumDialogPrms = 5; % Sampling Intervals, Mean Latency, Jitter, Loss Model (0: Indep., 1: Markov), Loss Params %
    Block.DialogPrmsTunable = {'Tunable', 'Tunable', 'Tunable', 'Tunable', 'Tunable'};
    Block.SampleTimes = [-2 0];
    Block.InputPort(1).SamplingMode = 'Sample';
    Block.InputPort(2).SamplingMode = 'Sample';
    Block.OutputPort(1).SamplingMode = 'Sample';
    Block.OutputPort(2).SamplingMode = 'Sample';
    Block.SimStateCompliance = 'DefaultSimState';
    Block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
    Block.RegBlockMethod('InitializeConditions', @InitializeConditions);
    Block.RegBlockMethod('Start', @Start);
    Block.RegBlockMethod('Outputs', @Outputs); 
    Block.RegBlockMethod('Update', @Update);
    Block.RegBlockMethod('Derivatives', @Derivatives);
    Block.RegBlockMethod('Terminate', @Terminate);
    Block.RegBlockMethod('SetInputPortDimensions',  @SetInpPortDims);
function DoPostPropSetup(Block)
    Block.NumDworks = 1;
    Block.Dwork(1).Name = 'id';
    Block.Dwork(1).Dimensions = 1;
    Block.Dwork(1).DatatypeID = 0; 
    Block.Dwork(1).Complexity = 'Real'; 
    Block.Dwork(1).UsedAsDiscState = true;
function InitializeConditions(Block)
function Start(Block)
    global Networks;
    id = size(Networks, 2) + 1;
    Networks{id}.NumOfChannels = 2;
    for i = 1:Networks{id}.NumOfChannels
        Networks{id}.Channels{i}.Buffer.Messages = [];
        Networks{id}.Channels{i}.Buffer.ReleaseTimes = [];
        Networks{id}.Channels{i}.LastPost = 0;
    end
    
    LossModel = Block.DialogPrm(4).Data;
    if LossModel == 1
        Networks{id}.LossState = 1;
    end
    
    Block.Dwork(1).Data = id;
function Outputs(Block)
function Update(Block)
    global Networks;
    id = Block.Dwork(1).Data;
    NumOfChannels = Networks{id}.NumOfChannels;
    ChannelNextHits = zeros(NumOfChannels, 1);
    for i = 1:NumOfChannels
        ChannelNextHits(i) = UpdateChannel(Block, i);
    end
    Block.NextTimeHit = min(ChannelNextHits);
function Derivatives(Block)
function Terminate(Block)
    global Networks;
    id = Block.Dwork(1).Data;
    Networks = [];
% Model functions
function ChannelNextHit = UpdateChannel(Block, channel)
    global Networks;
    id = Block.Dwork(1).Data;
    PostRate = Block.DialogPrm(1).Data(channel);
    if Block.CurrentTime - Networks{id}.Channels{channel}.LastPost + 1e-9 >= PostRate
        Networks{id}.Channels{channel}.LastPost = Block.CurrentTime;
        if ~Block.PacketLoss()
            Networks{id}.Channels{channel}.Buffer.Messages = [Networks{id}.Channels{channel}.Buffer.Messages, Block.InputPort(channel).Data];
            Networks{id}.Channels{channel}.Buffer.ReleaseTimes = [Networks{id}.Channels{channel}.Buffer.ReleaseTimes, Block.CurrentTime + Block.Latency()];
        end
    end
    if Block.CurrentTime + 1e-9 >= min(Networks{id}.Channels{channel}.Buffer.ReleaseTimes)
        [~, index] = min(Networks{id}.Channels{channel}.Buffer.ReleaseTimes);
        Block.OutputPort(3 - channel).Data = squeeze(Networks{id}.Channels{channel}.Buffer.Messages(:, index));
        Networks{id}.Channels{channel}.Buffer.ReleaseTimes(index) = [];
        Networks{id}.Channels{channel}.Buffer.Messages(:, index) = [];
    end
    ChannelNextHit = min([Networks{id}.Channels{channel}.Buffer.ReleaseTimes, Networks{id}.Channels{channel}.LastPost + PostRate]);
function latency = Latency(Block)
    MeanLatency = Block.DialogPrm(2).Data;
    Jitter = Block.DialogPrm(3).Data;
    latency = normrnd(MeanLatency, Jitter);
function loss = PacketLoss(Block)
    LossModel = Block.DialogPrm(4).Data;
    if LossModel == 0
        LossRate = Block.DialogPrm(5).Data;
        loss = rand() < LossRate;
    else
        global Networks;
        id = Block.Dwork(1).Data;
        LossParams = Block.DialogPrm(5).Data;
        [loss, Networks{id}.LossState] = GILossModel(Networks{id}.LossState, LossParams);
    end
function SetInpPortDims(Block, port, dims) 
    Block.InputPort(port).Dimensions = dims;
    Block.OutputPort(3 - port).Dimensions = dims;
