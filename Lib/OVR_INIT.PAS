Unit ovr_init;
{$X+}
Interface

Implementation
Uses overlay,crt;
const ovrbufsize=$18000; {$10000;}
begin
       OvrInit(paramstr(0));
       if OvrResult<>OvrOk then
       begin
               case OvrResult of
                OvrNotFound:writeln('Overlay file not found.');
               else writeln('Error initialization of overlay file.');
               end;
               halt(1);
       end;
       ovrInitEMS;
       if OvrResult<>ovrOk then
       begin
               write('Overlay not loaded to EMS: ');
               case OvrResult of
                ovrIOError: writeln('I/O error access to overlay file');
                ovrNoEMSDriver: writeln('EMS driver not found');
                ovrNoEMSMemory: writeln('Not enough EMS memory')
               end;
               writeln('Using base memory.');
               writeln(#13#10'Press any key...');
               wait;
       end;
       ovrSetBuf(ovrbufsize);
       if OvrResult<>OvrOk then
       begin
               write('Initialization error of overlay buffer: ');
               if OvrResult=ovrNoMemory then
                write('Not enough memory for Ovrbuffer');
               writeln(#13#10'Press any key...');
               wait;
               halt(2);
       end
end.