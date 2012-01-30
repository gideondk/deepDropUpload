/*
 * Jakefile
 * NewApplication
 *
 * Created by You on April 9, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Release",
    OS = require("os");

app ("DeepDropUpload", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "DeepDropUpload.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("DeepDropUpload");
    task.setIdentifier("com.yourcompany.DeepDropUpload");
    task.setVersion("1.0");
    task.setAuthor("Your Company");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("NewApplication");
    task.setSources((new FileList("**/*.j")).exclude(FILE.join("Build", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "DeepDropUpload"));
    print("----------------------------");
}

task ("default", ["DeepDropUpload"], function()
{
    printResults(configuration);
});

task ("build", ["default"]);

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("run", ["debug"], function()
{
    OS.system(["open", FILE.join("Build", "Debug", "DeepDropUpload", "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", "DeepDropUpload", "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", "DeepDropUpload"));
    OS.system(["press", "-f", FILE.join("Build", "Release", "DeepDropUpload"), FILE.join("Build", "Deployment", "DeepDropUpload")]);
    printResults("Deployment")
});
