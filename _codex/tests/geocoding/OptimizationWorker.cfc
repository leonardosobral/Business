component extends="FixtureAIWorker" output=false {
    public any function init(required array ids){super.init(ids[1]);variables.store=new OptimizationStore();variables.store.bindMany(ids);variables.reader=new OptimizationReader();refreshEconomy();return this;}
    public void function blockAI(){variables.store.blockAI();}
    public void function failFirst(){variables.reader.failFirst();}
    public void function setConflictingAI(){variables.ai=new OptimizationAI();refreshEconomy();}
    public void function throwOnRead(){variables.reader.throwOnRead();}
    public numeric function sourceCallCount(){return variables.reader.callCount();}
}
