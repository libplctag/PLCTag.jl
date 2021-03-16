using Test: @testset, @test, @test_throws, @test_broken
using CBinding
using Sockets
using Random
using PLCTag
using PLCTag.libplctag


include(Sys.islinux() ? "with-server.jl" : "without-server.jl")

