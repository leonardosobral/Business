component output="false" implements="inc.news_audio_provider_interface" {
  public binary function synthesize(required string input, required struct config) {
    if (!len(arguments.config.apiKey)) throw(type="NewsAudio.Configuration",message="OPENAI_API_KEY não configurada.");
    var result={}; var payload={model=arguments.config.model,voice=arguments.config.voice,speed=arguments.config.speed,response_format="mp3",input=arguments.input,instructions="Leia exatamente o texto fornecido, em português brasileiro. Use pronúncia brasileira, ritmo jornalístico ágil, entonação natural e pausas breves entre parágrafos. Não traduza, substitua, omita nem acrescente palavras."};
    var usageStarted=getTickCount();try{
    cfhttp(url="https://api.openai.com/v1/audio/speech",method="post",result="result",timeout="180",getAsBinary="yes") {
      cfhttpparam(type="header",name="Authorization",value="Bearer "&arguments.config.apiKey);
      cfhttpparam(type="header",name="Content-Type",value="application/json");
      cfhttpparam(type="body",value=serializeJSON(payload));
    }
    }finally{try{new services.openaiUsage.Observer().observe("news-audio","tts",arguments.config.model,result,getTickCount()-usageStarted);}catch(any telemetryUnavailable){}}
    var status=val(listFirst(result.statusCode?:"0"," "));
    if (status LT 200 OR status GTE 300) throw(type="NewsAudio.Provider",message="OpenAI TTS retornou HTTP "&status&".");
    if (!isBinary(result.fileContent?:"")) throw(type="NewsAudio.Provider",message="OpenAI TTS não retornou áudio binário.");
    return result.fileContent;
  }
}
