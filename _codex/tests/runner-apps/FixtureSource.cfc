component {
    this.calls=createObject('java','java.util.concurrent.atomic.AtomicInteger').init(0);
    this.mode='good';this.delay=500;
    public struct function fetch() {
        this.calls.incrementAndGet();
        sleep(this.delay);
        if (this.mode EQ 'fail') throw(message='Synthetic failure');
        if (this.mode EQ 'invalid') return {success=true,groups=[{items=['invalid']}],items=[]};
        if (this.mode EQ 'empty') return {success=true,groups=[],items=[]};
        return {success=true,groups=[{id=1,name='Fixture',items=[{label='fresh',href='/'}]}],items=[{label='fresh',href='/'}]};
    }
}
