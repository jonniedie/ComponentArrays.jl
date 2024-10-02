module ComponentArraysTruncatedStacktracesExt

using ComponentArrays
import TruncatedStacktraces: @truncate_stacktrace

@truncate_stacktrace ComponentArray 1
    
end