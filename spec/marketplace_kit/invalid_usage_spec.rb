describe 'invalid usage' do
  it 'aborts with usage when no arguments passed' do
    expect { execute_command('') }.to raise_error('Usage: nearme-marketpalce sync | deploy | pull')
  end

  it 'aborts when no .builder file found' do
    expect(File).to receive(:read).with("#{MarketplaceKit.builder_folder}.builder").and_raise(Errno::ENOENT)
    expect { execute_command('sync') }.to raise_error('Please create .builder file in order to continue.')
  end

  it 'handles server timeout' do
    stub_request(:post, 'http://localhost:3000/api/marketplace_builder/marketplace_releases').to_timeout
    expect { execute_command('deploy') }.to output(/Error: execution expired/).to_stdout
  end

  it 'handles empty response' do
    stub_request(:post, 'http://localhost:3000/api/marketplace_builder/marketplace_releases').to_return(status: 200, body: '')
    expect { execute_command('deploy') }.to output(/Error while parsing JSON/).to_stdout
  end

  it 'handles server errors' do
    stub_request(:post, 'http://localhost:3000/api/marketplace_builder/marketplace_releases').to_return(status: 500, body: 'Ups, 500!')
    expect { execute_command('deploy') }.to output(/Raw body:\nUps, 500!/).to_stdout
  end

  it 'handles marketplace builder errors' do
    stub_request(:post, 'http://localhost:3000/api/marketplace_builder/marketplace_releases').to_return(status: 500, body:
      { 'error' => 'Template path has already been taken', 'details' => { 'model_id' => 12, 'model_class' => 'Example' } }.to_json)

    expect { execute_command('deploy') }.to output(/Builder error: Template path has already been taken/).to_stdout
    expect { execute_command('deploy') }.to output(/"model_class"=>"Example"/).to_stdout
  end
end
