function vulcan {
    docker run -it `
        --network vulcan `
        --rm `
        -v "${PWD}:/workspace" `
        tmdcio/vulcan-spark:0.228.1.15 `
        vulcan $args
}