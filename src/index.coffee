fs = require "fs"
crypto = require "crypto"

module.exports = class CacheSigProcessor
  #Internal Stuff
  processFolder: (folder) -> #fn taken from keyword-brunch
    fs.readdir folder, (err, fileList) =>
      throw err if err
      fileList.forEach (file) =>
        filePath = "#{folder}/#{file}"
        @processFile filePath

  processFile: (file) -> #fn taken from keyword-brunch
    fs.exists file, (isExist) =>
      return console.log(file, "is not exist") if not isExist
      return @processFolder(file) if fs.lstatSync(file).isDirectory()
      return unless fileContent = fs.readFileSync file, "utf-8"

      resultContent = fileContent
      for keyword, processer of @keywordMap
        keywordRE = RegExp keyword, "g"
        resultContent = resultContent.replace keywordRE, processer
      fs.writeFileSync file, resultContent, "utf-8"

  getSignature: (seed) ->
    crypto.createHash('md5').update(seed).update(Date.now().toString()).digest('hex')

  #Brunch Stuff
  brunchPlugin: yes
  pattern: /.*/g

  constructor: (@config) ->
    @nameMap = {}
    @keywordMap = {}
    intString = @config?.plugins?.cacheSig?.intString ? '%sig%'
    @intRegExp = new RegExp(intString)
    @intRegExp.compile @intRegExp
    return

  onCompile: (gen_files) ->
    for file in gen_files
      #only process files with the sentinel value
      console.log file.path
      return unless @intRegExp.test file.path
      
      clean_name = file.path.replace(new RegExp("^.*/"), '')
      curr_name = @nameMap[clean_name] ? clean_name
      new_sig = @getSignature(curr_name)
      new_name = clean_name.replace @intRegExp, new_sig
      @keywordMap[curr_name] = @keywordMap[clean_name] = @nameMap[clean_name] = new_name
      console.log "#{clean_name} -> #{curr_name} -> #{new_name}"
      console.log @keywordMap

      fs.renameSync file.path, file.path.replace(@intRegExp, new_sig)
      @processFolder @config.paths.public