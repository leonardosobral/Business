<cfscript>
s=new __MANDALA__();checks=0;
for(n in ['','0','0000','-1','1.5','ABC','1e3','1234567890123','<script>']){
 rejected=false;try{s.number(n);}catch(ChallengeMandala.Validation e){rejected=true;}
 if(!rejected)throw(message='Invalid serial accepted');checks++;
}
if(compare(s.number(' 000123 '),'000123') NEQ 0)throw(message='Printed leading zeroes must be preserved');
writeOutput('CBG_MANDALA_VALIDATION_PASSED '&checks+1);
</cfscript>
