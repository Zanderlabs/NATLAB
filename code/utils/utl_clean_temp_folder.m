
function utl_clean_temp_folder ( opts )
% Delete temporarily stored data sets ("flushedsets") in BCILAB temp
% folder.

  % Attempt to clean temporarily stored data sets from bcilab temp directory
  try

    sPath_sets = fullfile ( opts.temp, 'flushedsets' );

    if ( exist ( sPath_sets, 'dir' ) )

      iNumDeleted = 0;

      % Get list of temporarily stored data sets
      aTmp = dir ( sPath_sets );

      for ( iFileIdx = 1:size ( aTmp, 1 ) )

        % Attempt to remove current .sto file
        try

          % Does the current file name end in "sto"
          if ( endsWith ( aTmp(iFileIdx).name, '.sto' ) )

            % Delete the file
            delete ( fullfile ( sPath_sets, aTmp(iFileIdx).name ) );

            iNumDeleted = iNumDeleted + 1;

          end

        catch e

          fprintf ( '\nWarning: Could not delete BCILAB temp file [%s].\n', aTmp(iFileIdx).name );

        end

      end

      if ( iNumDeleted > 0 )
      
        fprintf ( 'Deleted %d temporarily stored data sets (temp_auto_clean in bcilab_config is set to true).\n\n', iNumDeleted );

      else
        
        fprintf ( 'No temporarily stored data sets to delete (temp_auto_clean in bcilab_config is set to true).\n\n' );

      end
        
    end

  catch e

    fprintf ( '\nWarning: Failed to delete temporarily stored data sets.\n' );

  end

end